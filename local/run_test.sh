#!/bin/bash

# Copyright 2016 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

# This script is made from the kaldi recipe of the 2nd CHiME Challenge Track 2
# made by Chao Weng
# modified by @rezkitrianto

. ./path.sh
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

# Config:
nj=15
stage=2 # resume training with --stage=N
train=noisy # noisy data multi-condition training
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

if [ $# -ne 3 ]; then
  printf "\nUSAGE: %s <enhancement method> <enhanced speech directory> <chime4 root directory>\n\n" `basename $0`
  echo "First argument specifies a unique name for different enhancement method"
  echo "Second argument specifies the directory of enhanced wav files"
  echo "Third argument specifies the CHiME4 root directory"
  exit 1;
fi

# set enhanced data
enhan=$1
enhan_data=$2
# set chime4 data
chime4_data=$3

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

#####################
#### testing #########
# process for enhanced data
echo "------------STAGE 00----------"
if [ $stage -le 0 ]; then
  # echo "dprep"
  local/data_prep.sh $chime4_data
fi
# exit 1

echo "`basename GMM` Done." #RUN_GMM
# =============================================dnn part

# make fmllr feature for dev and eval
data_fmllr=data-fmllr-tri3b
gmmdir=exp/tri3b_tr05_multi_noisy
fmllrdir=fmllr-tri3b
lmfbdir=lmfb
echo "------------STAGE 1----------"
if [ $stage -le 1 ]; then
  steps/make_lmfb_forTest.sh --nj 1 --cmd "$train_cmd" \
    data/onlineTest_WuwRawTest1ch1 exp/make_lmfb/onlineTest_WuwRawTest1ch1 $lmfbdir
  steps/compute_cmvn_stats.sh data/onlineTest_WuwRawTest1ch1 exp/make_lmfb/onlineTest_WuwRawTest1ch1 $lmfbdir
# exit 1
echo "--------------------FMLLR-----------------"
  steps/nnet/make_fmllr_feats.sh --nj 1 --cmd "$train_cmd" \
    --transform-dir $gmmdir/decode_tgpr_5k_dt05_real_$enhan \
    $data_fmllr/onlineTest_WuwRawTest1ch1 data/onlineTest_WuwRawTest1ch1 $gmmdir exp/make_fmllr_tri3b/onlineTest_WuwRawTest1ch1 ${fmllrdir}/onlineTest_WuwRawTest1ch1
fi

# exit 1
dir=exp/tri4a_dnn_tr05_multi_${train}_smbr
echo "------------STAGE 2----------"
if [ $stage -le 2 ]; then
 # utils/mkgraph.sh data/lang_test_tgpr_5k $dir $dir/graph_tgpr_5k
 # v1 decoding
 # steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
 #    $dir/graph_tgpr_5k data/onlineTest $dir/decode_tgpr_5k_onlineTest

 # v2 decoding
  dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats

  for ITER in 4; do
  #  steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
  #     --nnet $dir/${ITER}.nnet --acwt 0.1 \
  #     exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/onlineTest2 $dir/decode_tgpr_5k_onlineTest2_it${ITER}_v2

  #   steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
  #      --nnet $dir/${ITER}.nnet --acwt 0.1 \
  #      exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/onlineTest3 $dir/decode_tgpr_5k_onlineTest3_it${ITER}_v2
   #
  #  steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
  #     --nnet $dir/${ITER}.nnet --acwt 0.1 \
  #     exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/onlineTest4 $dir/decode_tgpr_5k_onlineTest4_it${ITER}_v2

  steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
     --nnet $dir/${ITER}.nnet --acwt 0.1 --determinize=false \
     exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/onlineTest_WuwRawTest1ch1 $dir/decode_tgpr_5k_onlineTestWuw1ch1_it${ITER}_v3

   steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt 0.1 --determinize=false \
      /home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_wuw $data_fmllr/onlineTest_WuwRawTest1ch1 $dir/decode_tgpr_5k_onlineTestWuw1ch1_it${ITER}_v3_grammar2
  done

  # v3 decoding:
  # steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
  #    /home/rezki/Downloads/api.ai-kaldi-asr-model data/onlineTest /home/rezki/Downloads/api.ai-kaldi-asr-model/decode_tgpr_5k_onlineTest

  #v4 decoding:
  # steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --acwt 0.10 --config conf/decode_dnn.config \
  #    $dir data/onlineTest2 $dir/decode_tgpr_5k_onlineTest2
fi

exit 1
echo "------------STAGE 3----------"
if [ $stage -le 3 ]; then
  cat $dir/decode_tgpr_5k_dt05_{real,simu}_${enhan}_it$x/$y | grep WER | awk '{err+=$4} {wrd+=$6} END{printf("%.2f\n",err/wrd*100)}'
 # v2 decoding
  dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats


fi
