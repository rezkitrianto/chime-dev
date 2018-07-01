#!/bin/bash

nj=12
stage=1
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

if [ $# -ne 0 ]; then
  printf "\nUSAGE: %s <enhancement method> <model dir>\n\n" `basename $0`
  echo "First argument specifies a unique name for different enhancement method"
  echo "Second argument specifies acoustic and language model directory"
  exit 1;
fi

# set language models
lm_suffix=${order}gkn_5k
rnnlm_suffix=rnnlm_5k_h${hidden}

#--------LSTM parameter -------------
#author : Rezki Trianto
lstmweight=1.0
lstmlm_suffix=lstmlm_5k_h${hidden}

# enhan data
enhan=beamformit_5mics
# set model directory
# srcdir=exp/tri4a_dnn_tr05_multi_${train}_smbr_i1lats
# srcdir=exp/chain/tdnn1a_sp_lmrescore
# srcdir=exp/chain/tdnn_blstm_1a_5layers_sp_lmrescore
srcdir=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/nnet_tdnn_a_ivec_fmllr_lmrescore
srcdir2=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/lstm_4_ivec_fmllr_ld5_lmrescore
srcdir2=/media/rezki/DATA2/exp-to-rescore/exp/tri4a_dnn_tr05_multi_noisy_norbm_lmrescore
srcdir3=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_7layers_sp_lmrescore
srcdir3=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector_lmrescore
# srcdir3=/media/rezki/DATA2/exp-to-rescore/exp/nnet3/blstm_3layers_ivec_fmllr_bidirectional_lmrescore
# preparation
#dir=exp/tri4a_dnn_tr05_multi_${train}_smbr_lmrescore
#mkdir -p $dir
# make a symbolic link to graph info
#if [ ! -e $dir/graph_tgpr_5k ]; then
#  if [ ! -e exp/tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k ]; then
#    echo "graph is missing, execute local/run_dnn.sh, correctly"
#    exit 1;
#  fi
#  pushd . ; cd $dir
#  ln -s ../tri4a_dnn_tr05_multi_${train}/graph_tgpr_5k .
#  popd
#fi

# rescore lattices by a high-order N-gram
if [ $stage -le 3 ]; then
  # check the best iteration
  if [ ! -f $srcdir/log/best_wer_${enhan}_rnnlm_5k_h300_w0.5_n100 ]; then
    echo "$0: error $srcdir/log/best_wer_$enhan not found. execute local/run_dnn.sh, first"
    exit 1;
  fi
  it=`cut -f 1 -d" " $srcdir/log/best_wer_${enhan}_rnnlm_5k_h300_w0.5_n100 | awk -F'[_]' '{print $1}'`
  # rescore lattices
  if $eval_flag; then
    tasks="dt05_simu dt05_real et05_simu et05_real"
  else
    tasks="dt05_simu dt05_real"
  fi
  for t in $tasks; do
    #steps/lmrescore.sh --mode 3 \
    #  $mdir/data/lang_test_tgpr_5k \
    #  $mdir/data/lang_test_${lm_suffix} \
    #  data-fmllr-tri3b/${t}_$enhan \
    #  $srcdir/decode_tgpr_5k_${t}_${enhan}_it$it \
    #  $dir/decode_tgpr_5k_${t}_${enhan}_${lm_suffix}

    # lmrescore_theanolm_nbest.sh \
  	# 	/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_tgpr_5k \
  	# 	/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/local/local_lm/trainlstmResult/model2.h5 \
  	# 	$srcdir/decode_tdnn_${t}_${enhan}_rnnlm_5k_h300_w0.5_n100  \
  	# 	$srcdir/decode_tdnn_${t}_${enhan}_lstmlm1500 \
  	# 	${t}

    lmrescore_theanolm_nbest.sh \
  		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_tgpr_5k \
  		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/local/local_lm/trainlstmResult/model2.h5 \
  		$srcdir2/decode_${t}_${enhan}_rnnlm_5k_h300_w0.5_n100  \
  		$srcdir2/decode_${t}_${enhan}_lstmlm1500 \
  		${t}

    lmrescore_theanolm_nbest.sh \
  		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_tgpr_5k \
  		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/local/local_lm/trainlstmResult/model.h5 \
  		$srcdir2/decode_${t}_${enhan}_rnnlm_5k_h300_w0.5_n100  \
  		$srcdir2/decode_${t}_${enhan}_lstmlm300 \
  		${t}

#fast-blstm
    # lmrescore_theanolm_nbest.sh \
  	# 	/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_tgpr_5k \
  	# 	/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/local/local_lm/trainlstmResult/model.h5 \
  	# 	$srcdir3/decode2_${t}_${enhan}_sw1_tg_rnnlm_5k_h300_w0.5_n100  \
  	# 	$srcdir3/decode2_${t}_${enhan}_sw1_tg_lstmlm300 \
  	# 	${t}
    #
    #   lmrescore_theanolm_nbest.sh \
    # 		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_tgpr_5k \
    # 		/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/local/local_lm/trainlstmResult/model2.h5 \
    # 		$srcdir3/decode2_${t}_${enhan}_sw1_tg_rnnlm_5k_h300_w0.5_n100  \
    # 		$srcdir3/decode2_${t}_${enhan}_sw1_tg_lstmlm1500 \
    # 		${t}
  done
fi
