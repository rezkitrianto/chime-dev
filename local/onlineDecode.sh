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
 # 2 step of decoding:
 # 	a.) use GMM model to get the transcription
 # 	b.) align the transcription and make the fMLLR feature
 # 	c.) use DNN model to get the transcription
# Config:
nj=15
stage=2 # resume training with --stage=N
train=noisy # noisy data multi-condition training
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

# if [ $# -ne 3 ]; then
#   printf "USAGE ------------- local/onlineDecode.sh --stage 0 enhan filepath utterance"
#   exit 1;
# fi

# enhan=$1


filepath="$1"
utterance_text="$2"
# enhan=noisy
enhan=beamformit_5mics

filename=$(basename "$filepath")
extension="${filename##*.}"
filename="${filename%.*}"

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
  local/data_prep_onlineDecode.sh "$filepath" "$utterance_text"
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
    data/onlineTest_real2 exp/make_lmfb/onlineTest_real2 $lmfbdir
  steps/compute_cmvn_stats.sh data/onlineTest_real2 exp/make_lmfb/onlineTest_real2 $lmfbdir
# exit 1
# echo "--------------------FMLLR-----------------"
  # steps/nnet/make_fmllr_feats.sh --nj 1 --cmd "$train_cmd" \
  #   --transform-dir $gmmdir/decode_tgpr_5k_dt05_real_$enhan \
  #   $data_fmllr/onlineTest_real2 data/onlineTest_real2 $gmmdir exp/make_fmllr_tri3b/onlineTest_real2 ${fmllrdir}/onlineTest_real2
fi
  # $data_fmllr/onlineTest4 data/onlineTest4 $gmmdir exp/make_fmllr_tri3b/onlineTest4 ${fmllrdir}/onlineTest4
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

  # how to decode use fMLLR feats: (best decode result)
  # decode use gmm first
  #  with fmllrdir
  # make fmllr feats
  # compute cmvn normalization


  # steps/decode_fmllr.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config  \
  #   exp/tri3b_tr05_multi_${train}/graph_tgpr_5k data/onlineTest_real2 exp/tri3b_tr05_multi_${train}/decode_onlineTest_real2

  steps/align_fmllr.sh --nj 1 --cmd "$train_cmd" \
    data/onlineTest_real2 data/lang exp/tri3b_tr05_multi_${train} exp/tri3b_tr05_multi_${train}_ali

  gmmdir2=exp/tri3b_tr05_multi_${train}_ali
  data_fmllr=data-fmllr-tri3b
  fmllrdir=fmllr-tri3b/${train}

  steps/nnet/make_fmllr_feats.sh --nj 1 --cmd "$train_cmd" \
    --transform-dir $gmmdir2 \
    $data_fmllr/onlineTest_real2 data/onlineTest_real2 $gmmdir2 exp/make_fmllr_tri3b/onlineTest_real2 $fmllrdir

  for ITER in 4; do
    steps/nnet/decode.sh --nj 1 --num-threads 8 --cmd "$decode_cmd" --config conf/decode_dnn.config \
     --nnet $dir/${ITER}.nnet --acwt 0.1 \
     exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $data_fmllr/onlineTest_real2 $dir/decode_tgpr_5k_onlineTest_real2_it${ITER}_v3
  done

  # use this decode script to decode by using the LMFB feats. result not really good
  # for ITER in 4; do
  # # steps/nnet/decode.sh --nj 1 --num-threads 1 --cmd "$decode_cmd" --config conf/decode_dnn.config \
  # #    --nnet $dir/${ITER}.nnet --acwt 0.1 \
  # #    exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k data/onlineTest_real2 $dir/decode_tgpr_5k_onlineTest_real2_it${ITER}_v3
  # done

  local/chime4_calc_wers_online.sh $dir $enhan exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k $filename
  # local/chime4_calc_wers_online.sh exp/tri3b_tr05_multi_${train} $enhan exp/tri3b_tr05_multi_${train}/graph_tgpr_5k $filename
  # head -n 15 exp/tri4a_dnn_tr05_multi_${train}/best_wer_online.result
  # echo "WER : "
  head -n 15 ${dir}/log/best_wer_online_${enhan}
fi

exit 1
