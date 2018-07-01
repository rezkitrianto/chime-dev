#!/bin/bash

# Copyright 2016 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

# This script is made from the kaldi recipe of the 2nd CHiME Challenge Track 2
# made by Chao Weng

. ./path.sh
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

# Config:
nj=3
stage=6 # resume training with --stage=N
train=noisy
#eval_flag=true # make it true when the evaluation data are released
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

if [ $# -ne 1 ]; then
  printf "\nUSAGE: %s <enhancement method>\n\n" `basename $0`
  echo "First argument specifies a unique name for different enhancement method"
  exit 1;
fi

# set enhanced data
enhan=$1

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

# check whether run_init is executed
if [ ! -d data/lang ]; then
  echo "error, execute local/run_init.sh, first"
  exit 1;
fi

# check whether run_init is executed
if [ ! -d exp/tri3b_tr05_multi_${train} ]; then
  echo "error, execute local/run_init.sh, first"
  exit 1;
fi

# get alignments
echo "------------STAGE 0----------"
if [ $stage -le 0 ]; then
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/tr05_multi_${train} data/lang exp/tri3b_tr05_multi_${train} exp/tri3b_tr05_multi_${train}_ali
  steps/align_fmllr.sh --nj 4 --cmd "$train_cmd" \
    data/dt05_multi_$enhan data/lang exp/tri3b_tr05_multi_${train} exp/tri3b_tr05_multi_${train}_ali_dt05
fi

# make fmllr feature for training multi = simu + real
gmmdir=exp/tri3b_tr05_multi_${train}_ali
data_fmllr=data-fmllr-tri3b
mkdir -p $data_fmllr
fmllrdir=fmllr-tri3b/${train}
echo "------------STAGE 1----------"
if [ $stage -le 1 ]; then
  for x in tr05_real_${train} tr05_simu_${train}; do
   # steps/nnet/make_fmllr_feats.sh --nj 4 --cmd "$train_cmd" \
   #   --transform-dir $gmmdir \
   #   $data_fmllr/$x data/$x $gmmdir exp/make_fmllr_tri3b/$x $fmllrdir

    steps/compute_cmvn_stats.sh $data_fmllr/$x exp/make_fmllr_tri3b/$x $fmllrdir/$x

  done
fi

# make fmllr feature for dev and eval
gmmdir=exp/tri3b_tr05_multi_${train}
fmllrdir=fmllr-tri3b/$enhan
echo "------------STAGE 2----------"
if [ $stage -le 2 ]; then
  if $eval_flag; then
    tasks="dt05_real_$enhan dt05_simu_$enhan et05_real_$enhan et05_simu_$enhan"
  else
    #tasks="dt05_real_$enhan dt05_simu_$enhan"
    tasks="dt05_real_$enhan dt05_simu_$enhan"
  fi
  for x in $tasks; do
   # steps/nnet/make_fmllr_feats.sh --nj 4 --cmd "$train_cmd" \
   #   --transform-dir $gmmdir/decode_tgpr_5k_$x \
   #   $data_fmllr/$x data/$x $gmmdir exp/make_fmllr_tri3b/$x $fmllrdir

    steps/compute_cmvn_stats.sh $data_fmllr/$x exp/make_fmllr_tri3b/$x $fmllrdir/$x
  done
fi

#exit 1

# make mixed training set from real and simulation enhanced data
# multi = simu + real
echo "------------STAGE 3----------"
if [ $stage -le 3 ]; then
  for data_dir in $data_fmllr/tr05_real_${train} $data_fmllr/tr05_simu_${train} $data_fmllr/dt05_real_$enhan $data_fmllr/dt05_simu_$enhan; do
    utils/data/get_utt2dur.sh $data_dir
  done

  utils/combine_data.sh $data_fmllr/tr05_multi_${train} $data_fmllr/tr05_simu_${train} $data_fmllr/tr05_real_${train}
  utils/combine_data.sh $data_fmllr/dt05_multi_$enhan $data_fmllr/dt05_simu_$enhan $data_fmllr/dt05_real_$enhan
  if $eval_flag; then
    for data_dir in $data_fmllr/et05_real_$enhan $data_fmllr/et05_simu_$enhan; do
      utils/data/get_utt2dur.sh $data_dir
    done
    utils/combine_data.sh $data_fmllr/et05_multi_$enhan $data_fmllr/et05_simu_$enhan $data_fmllr/et05_real_$enhan
  fi
fi

# exit 1
#sys.exit()

# pre-train dnn
dir=exp/tri4a_dnn_pretrain_tr05_multi_${train}
echo "------------STAGE 4----------"
if [ $stage -le 4 ]; then
  $cuda_cmd $dir/_pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --nn-depth 7 --rbm-iter 3 $data_fmllr/tr05_multi_${train} $dir
fi

# train dnn
dir=exp/tri4a_dnn_tr05_multi_${train}
ali=exp/tri3b_tr05_multi_${train}_ali
ali_dev=exp/tri3b_tr05_multi_${train}_ali_dt05
feature_transform=exp/tri4a_dnn_pretrain_tr05_multi_${train}/final.feature_transform
dbn=exp/tri4a_dnn_pretrain_tr05_multi_${train}/7.dbn
echo "------------STAGE 5----------"
if [ $stage -le 5 ]; then
  $cuda_cmd $dir/_train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
    $data_fmllr/tr05_multi_${train} $data_fmllr/dt05_multi_$enhan data/lang $ali $ali_dev $dir
fi

# decode enhanced speech
echo "------------STAGE 6----------"
if [ $stage -le 6 ]; then
 # utils/mkgraph.sh data/lang_test_wuw $dir $dir/graph_wuw
 # exit 1
 utils/mkgraph.sh data/lang_test_tgpr_5k $dir $dir/graph_tgpr_5k
 steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
    $dir/graph_tgpr_5k $data_fmllr/dt05_real_$enhan $dir/decode_tgpr_5k_dt05_real_$enhan &
 steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
   $dir/graph_tgpr_5k $data_fmllr/dt05_simu_$enhan $dir/decode_tgpr_5k_dt05_simu_$enhan &
 #exit 1
if $eval_flag; then
  steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
    $dir/graph_tgpr_5k $data_fmllr/et05_real_$enhan $dir/decode_tgpr_5k_et05_real_$enhan &
  steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
    $dir/graph_tgpr_5k $data_fmllr/et05_simu_$enhan $dir/decode_tgpr_5k_et05_simu_$enhan &
  fi
  wait;
fi

# Sequence training using sMBR criterion, we do Stochastic-GD
# with per-utterance updates. We use usually good acwt 0.1
# Lattices are re-generated after 1st epoch, to get faster convergence.
dir=exp/tri4a_dnn_tr05_multi_${train}_smbr
srcdir=exp/tri4a_dnn_tr05_multi_${train}
acwt=0.1

# First we generate lattices and alignments:
# gawk must be installed to perform awk -v FS="/" '{ print gensub(".gz","","",$NF)" gunzip -c "$0" |"; }' in
# steps/nnet/make_denlats.sh
echo "------------STAGE 7----------"
if [ $stage -le 7 ]; then
  steps/nnet/align.sh --nj $nj --cmd "$train_cmd" \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_ali
  steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_denlats
fi

# Re-train the DNN by 1 iteration of sMBR
echo "------------STAGE 8----------"
if [ $stage -le 8 ]; then
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 1 --acwt $acwt --do-smbr true \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
fi

# Decode (reuse HCLG graph)
echo "------------STAGE 9----------"
if [ $stage -le 9 ]; then
  for ITER in 1; do
    steps/nnet/decode.sh --nj 2 --num-threads 2 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/dt05_real_${enhan} $dir/decode_tgpr_5k_dt05_real_${enhan}_it${ITER} &
    steps/nnet/decode.sh --nj 2 --num-threads 2 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/dt05_simu_${enhan} $dir/decode_tgpr_5k_dt05_simu_${enhan}_it${ITER} &
    if $eval_flag; then
    steps/nnet/decode.sh --nj 2 --num-threads 2 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/et05_real_${enhan} $dir/decode_tgpr_5k_et05_real_${enhan}_it${ITER} &
    steps/nnet/decode.sh --nj 2 --num-threads 2 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/et05_simu_${enhan} $dir/decode_tgpr_5k_et05_simu_${enhan}_it${ITER} &
    fi
  done
fi

# Re-generate lattices, run 4 more sMBR iterations
dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats
srcdir=exp/tri4a_dnn_tr05_multi_${train}_smbr
acwt=0.1

# Generate lattices and alignments:
echo "------------STAGE 10----------"
if [ $stage -le 10 ]; then
  steps/nnet/align.sh --nj $nj --cmd "$train_cmd" \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_ali
  steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_denlats
fi

# Re-train the DNN by 4 iterations of sMBR
echo "------------STAGE 11----------"
if [ $stage -le 11 ]; then
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 4 --acwt $acwt --do-smbr true \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
fi

# Decode (reuse HCLG graph)
echo "------------STAGE 12----------"
if [ $stage -le 12 ]; then
  for ITER in 1 2 3 4; do
   steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/dt05_real_${enhan} $dir/decode_tgpr_5k_dt05_real_${enhan}_it${ITER}

    steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/dt05_simu_${enhan} $dir/decode_tgpr_5k_dt05_simu_${enhan}_it${ITER}

    if $eval_flag; then
    steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/et05_real_${enhan} $dir/decode_tgpr_5k_et05_real_${enhan}_it${ITER}
    steps/nnet/decode.sh --nj 3 --num-threads 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/et05_simu_${enhan} $dir/decode_tgpr_5k_et05_simu_${enhan}_it${ITER}

    fi
  done
  wait
fi

# scoring
echo "------------STAGE 13----------"
if [ $stage -le 13 ]; then
  # decoded results of enhanced speech using DNN AMs trained with enhanced data
  local/chime4_calc_wers.sh exp/tri4a_dnn_tr05_multi_${train} $enhan exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k \
    > exp/tri4a_dnn_tr05_multi_${train}/best_wer_$enhan.result
  head -n 15 exp/tri4a_dnn_tr05_multi_${train}/best_wer_$enhan.result


  # decoded results of enhanced speech using sequence-training DNN
  ./local/chime4_calc_wers_smbr.sh exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats ${enhan} exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k \
    > exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats/best_wer_${enhan}.result
  head -n 15 exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats/best_wer_${enhan}.result
fi

# Re-generate lattices, run 4 more sMBR iterations
dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats
srcdir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats
acwt=0.1
# Generate lattices and alignments:
echo "------------STAGE 14----------"
if [ $stage -le 14 ]; then
  steps/nnet/align.sh --nj $nj --cmd "$train_cmd" \
    $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_ali
  # steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
  #   $data_fmllr/tr05_multi_${train} data/lang $srcdir ${srcdir}_denlats
fi

exit 1
echo "`basename $0` Done."