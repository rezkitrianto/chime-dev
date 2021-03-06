#!/bin/bash

# Copyright 2015 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

# Copyright 2015, Mitsubishi Electric Research Laboratories, MERL (Author: Takaaki Hori)

nj=12
stage=4
order=5
hidden=300
rnnweight=0.5
nbest=100
train=noisy
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

. ./path.sh
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

if [ $# -ne 2 ]; then
  printf "\nUSAGE: %s <Chime4 root directory> <enhancement method>\n\n" `basename $0`
  echo "First argument specifies a root directory of Chime4 data"
  echo "Second argument specifies a unique name for different enhancement method"
  exit 1;
fi

# set language models
lm_suffix=${order}gkn_5k
rnnlm_suffix=rnnlm_5k_h${hidden}

# data root
chime4_data=$1
# enhan data
enhan=$2

# check data
if [ ! -d $chime4_data ]; then
  echo "$chime4_data does not exist. Please specify chime4 data root correctly" && exit 1
fi

# check whether run_dnn is executed
# srcdir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats
# srcdir=exp/nnet3/nnet_tdnn_a_ivec_fmllr
# srcdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn1a_sp
# srcdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn31a_sp_blstm_v3_5layers
# srcdir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/nnet_tdnn_a_ivec_fmllr
srcdir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/lstm_4_ivec_fmllr_ld5
srcdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_7layers_sp
srcdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector
# srcdir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/blstm_3layers_ivec_fmllr_bidirectional
srcdir=/media/rezki/DATA2/exp-to-rescore/exp/tri4a_dnn_tr05_multi_noisy_norbm
# tdnn31a_sp_blstm_v3_5layers
if [ ! -d $srcdir ]; then
  echo "error, execute local/run_dnn.sh, first"
  exit 1;
fi

# train a high-order n-gram language model
echo "----------------Stage 1--------------"
if [ $stage -le 1 ]; then
  local/chime4_train_lms.sh $chime4_data || exit 1;
fi

# train a RNN language model
echo "----------------Stage 2--------------"
if [ $stage -le 2 ]; then
  local/chime4_train_rnnlms.sh $chime4_data || exit 1;
fi

# preparation
# dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_lmrescore
# dir=exp/nnet3/nnet_tdnn_a_ivec_fmllr_lmrescore
# dir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn1a_sp_lmrescore
# dir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn31a_sp_blstm_v3_5layers_lmrescore
# dir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/nnet_tdnn_a_ivec_fmllr_lmrescore
dir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/lstm_4_ivec_fmllr_ld5_lmrescore
dir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_7layers_sp_lmrescore
dir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector_lmrescore
# dir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/blstm_3layers_ivec_fmllr_bidirectional_lmrescore
dir=/media/rezki/DATA2/exp-to-rescore/exp/tri4a_dnn_tr05_multi_noisy_norbm_lmrescore
mkdir -p $dir
# make a symbolic link to graph info
if [ ! -e $dir/graph_tgpr_5k ]; then
  if [ ! -e exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k ]; then
    echo "graph is missing, execute local/run_dnn.sh, correctly"
    exit 1;
  fi
  pushd . ; cd $dir
  ln -s ../tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k .
  popd
fi

# rescore lattices by a high-order N-gram
echo "----------------Stage 3--------------"
if [ $stage -le 3 ]; then
  # check the best iteration
  # if [ ! -f $srcdir/log/best_wer_$enhan ]; then
  #   echo "error, execute local/run_dnn.sh, first"
  #   exit 1;
  # fi
  # it=`cut -f 1 -d" " $srcdir/log/best_wer_$enhan | awk -F'[_]' '{print $1}'`
  it=13
  # rescore lattices
  if $eval_flag; then
    tasks="dt05_simu dt05_real et05_simu et05_real"
  else
    tasks="dt05_simu dt05_real"
  fi
  # tasks="et05_real"
#   for t in $tasks; do
#     # steps/lmrescore.sh --mode 3 \
#     #   data/lang_test_tgpr_5k \
#     #   data/lang_test_${lm_suffix} \
#     #   data-fmllr-tri3b/${t}_$enhan \
#     #   $srcdir/decode_tgpr_5k_${t}_${enhan}_it$it \
#     #   $dir/decode_tgpr_5k_${t}_${enhan}_${lm_suffix}
#
#       # steps/lmrescore.sh --mode 3 \
#       #   data/lang_test_tgpr_5k \
#       #   data/lang_test_${lm_suffix} \
#       #   data-fmllr-tri3b/${t}_$enhan \
#       #   $srcdir/decode_tdnn_${t}_${enhan} \
#       #   $dir/decode_tdnn_${t}_${enhan}_${lm_suffix}
#
#         steps/lmrescore.sh --mode 3 \
#           data/lang_test_tgpr_5k \
#           data/lang_test_${lm_suffix} \
#           data-fmllr-tri3b/${t}_$enhan \
#           $srcdir/decode_${t}_${enhan} \
#           $dir/decode_${t}_${enhan}_${lm_suffix}
#
# #fast-blstm
#           # steps/lmrescore.sh --mode 3 \
#           #   data/lang_test_tgpr_5k \
#           #   data/lang_test_${lm_suffix} \
#           #   data-fmllr-tri3b/${t}_$enhan \
#           #   $srcdir/decode2_${t}_${enhan}_sw1_tg \
#           #   $dir/decode2_${t}_${enhan}_sw1_tg_${lm_suffix}
#   done
  # rescored results by high-order n-gram LM
  # exit 1
  mkdir -p $dir/log
  # local/chime4_calc_wers.sh $dir ${enhan}_${lm_suffix} $dir/graph_tgpr_5k \
  #     > $dir/best_wer_${enhan}_${lm_suffix}.result
# exit 1
  # local/chime4_calc_wers_tdnn.sh $dir ${enhan}_${lm_suffix} $dir/graph_tgpr_5k \
  #     > $dir/best_wer_${enhan}_${lm_suffix}.result
  graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k
  # graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector/graph_sw1_tg
  # local/chime4_calc_wers_fastlstm.sh $dir ${enhan}_${lm_suffix} $graphdir \
  #     > $dir/best_wer_${enhan}_${lm_suffix}.result
  # local/chime4_calc_wers_fastblstm.sh $dir ${enhan}_sw1_tg_${lm_suffix} $graphdir \
  #    > $dir/best_wer_${enhan}_${lm_suffix}.result
  # local/chime4_calc_wers_blstm.sh $dir ${enhan}_${lm_suffix} $graphdir \
  #   > $dir/best_wer_${enhan}_${lm_suffix}.result
  # local/chime4_calc_wers_tdnn.sh $dir ${enhan}_${lm_suffix} $graphdir \
  #     > $dir/best_wer_${enhan}_${lm_suffix}.result
  local/chime4_calc_wers_lstm.sh $dir ${enhan}_${lm_suffix} $graphdir \
      > $dir/best_wer_${enhan}_${lm_suffix}.result
  head -n 15 $dir/best_wer_${enhan}_${lm_suffix}.result
fi

# exit 1
# N-best rescoring using a RNNLM
echo "----------------Stage 4--------------"
if [ $stage -le 4 ]; then
  # check the best lmw
  # if [ ! -f $dir/log/best_wer_${enhan}_${lm_suffix} ]; then
  #   echo "error, rescoring with a high-order n-gram seems to be failed"
  #   exit 1;
  # fi
  # lmw=`cut -f 1 -d" " $dir/log/best_wer_${enhan}_${lm_suffix} | awk -F'[_]' '{print $NF}'`

  lmw=`cut -f 1 -d" " $dir/log/best_wer_${enhan}_${lm_suffix} | awk -F'[_]' '{print $NF}'`
  echo $lmw
  # rescore n-best list for all sets
  if $eval_flag; then
    tasks="dt05_simu dt05_real et05_simu et05_real"
  else
    tasks="dt05_simu dt05_real"
  fi
  for t in $tasks; do
    # steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
    #   $rnnweight \
    #   data/lang_test_${lm_suffix} \
    #   data/lang_test_${rnnlm_suffix} \
    #   data-fmllr-tri3b/${t}_$enhan \
    #   $dir/decode_graph_tgpr_5k_${t}_${enhan}_${lm_suffix} \
    #   $dir/decode_graph_tgpr_5k_${t}_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}

#tdnn
      # steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
      #   $rnnweight \
      #   data/lang_test_${lm_suffix} \
      #   data/lang_test_${rnnlm_suffix} \
      #   data-fmllr-tri3b/${t}_$enhan \
      #   $dir/decode_tdnn_${t}_${enhan}_${lm_suffix} \
      #   $dir/decode_tdnn_${t}_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}

# #lstm
      # steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
      #   $rnnweight \
      #   data/lang_test_${lm_suffix} \
      #   data/lang_test_${rnnlm_suffix} \
      #   data-fmllr-tri3b/${t}_$enhan \
      #   $dir/decode_${t}_${enhan}_${lm_suffix} \
      #   $dir/decode_${t}_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}

#fast-blstm
        # steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
        #   $rnnweight \
        #   data/lang_test_${lm_suffix} \
        #   data/lang_test_${rnnlm_suffix} \
        #   data-fmllr-tri3b/${t}_$enhan \
        #   $dir/decode2_${t}_${enhan}_sw1_tg_${lm_suffix} \
        #   $dir/decode2_${t}_${enhan}_sw1_tg_${rnnlm_suffix}_w${rnnweight}_n${nbest}

    # steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
    #   $rnnweight \
    #   data/lang_test_${lm_suffix} \
    #   data/lang_test_${rnnlm_suffix} \
    #   data-fmllr-tri3b/${t}_$enhan \
    #   $dir/decode_tdnn_${t}_${enhan}_${lm_suffix} \
    #   $dir/decode_tdnn_${t}_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}

    steps/rnnlmrescore.sh --inv-acwt $lmw --N $nbest --use-phi true \
      $rnnweight \
      data/lang_test_${lm_suffix} \
      data/lang_test_${rnnlm_suffix} \
      data-fmllr-tri3b/${t}_$enhan \
      $dir/decode_${t}_${enhan}_${lm_suffix} \
      $dir/decode_${t}_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}
  done
  # exit 1
  # calc wers for RNNLM results
  # local/chime4_calc_wers.sh $dir ${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest} $dir/graph_tgpr_5k \
  #     > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  # local/chime4_calc_wers_tdnn.sh $dir ${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest} $dir/graph_tgpr_5k \
  #     > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k
    local/chime4_calc_wers_lstm.sh $dir ${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest} $graphdir\
        > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  # graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector/graph_sw1_tg
  # local/chime4_calc_wers_fastblstm.sh $dir ${enhan}_sw1_tg_${rnnlm_suffix}_w${rnnweight}_n${nbest} $graphdir\
  #      > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  # local/chime4_calc_wers_fastlstm.sh $dir ${enhan}_sw1_tg_${rnnlm_suffix}_w${rnnweight}_n${nbest} $graphdir\
  #      > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  # graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k
  # local/chime4_calc_wers_blstm.sh $dir ${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest} $graphdir\
  #     > $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
  head -n 15 $dir/best_wer_${enhan}_${rnnlm_suffix}_w${rnnweight}_n${nbest}.result
fi
exit 1
