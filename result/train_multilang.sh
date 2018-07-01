#!/bin/bash

# Kaldi ASR baseline for the CHiME-4 Challenge (6ch track: 6 channel track)
#
# Copyright 2016 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh
. ./cmd.sh

# Config:
stage=7 # resume training with --stage=N
flatstart=true

. utils/parse_options.sh || exit 1;

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

#####check data and model paths################
# Set a main root directory of the CHiME4 data
# If you use scripts distributed in the CHiME4 package,
chime4_data=`pwd`/../..
# Otherwise, please specify it, e.g.,
# chime4_data=/db/laputa1/data/processed/public/CHiME4
#chime4_data=/home/mslab-deep/CHiME4/CHiME3
chime4_data=/mnt/Data/dataset/CHiME4/CHiME3
#chime4_data=/home/rezki/sandbox/dataset/CHiME3
if [ ! -d $chime4_data ]; then
  echo "$chime4_data does not exist. Please specify chime4 data root correctly" && exit 1
fi
# Set a model directory for the CHiME4 data.
modeldir=$chime4_data/tools/ASR_models
for d in $modeldir $modeldir/data/{lang,lang_test_tgpr_5k,lang_test_5gkn_5k,lang_test_rnnlm_5k_h300,local} \
  $modeldir/exp/{tri3b_tr05_multi_noisy,tri4a_dnn_tr05_multi_noisy,tri4a_dnn_tr05_multi_noisy_smbr_i1lats}; do
  [ ! -d ] && echo "$0: no such directory $d. specify models correctly or execute './run.sh --flatstart true' first" && exit 1;
done
#####check data and model paths finished#######


#####main program start################
# You can execute run_init.sh only "once"
# This creates 3-gram LM, FSTs, and basic task files
if [ $stage -le 7 ] && $flatstart; then
  # Usage: $0 [opts] <data> <lang> <ali-dir> <denlat-dir> <src-model-file> <degs-dir>
  # steps/nnet2/get_egs_discriminative2_chime4.sh \
  #   data/tr05_multi_noisy \ #data
  #   data/lang \ #lang
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_ali \ #ali-dir
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_denlats \ #denlat-dir
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr/final.mdl \ #src-model-file
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_degs/degs #degs-dir

  # Usage: $0 [opts] <degs-dir1> <degs-dir2> ... <degs-dirN>  <exp-dir>
  # steps/nnet2/train_discriminative2_multilang2_chime4.sh \
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_nnet2 \ #egs-dir1
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_nnet2 \ #egs-dir2
  #   exp/tri4a_dnn_tr05_multi_noisy_smbr_nnet2_multilang #exp-dir

  # Usage: $0 [opts] <data> <ali-dir> <egs-dir>
  # steps/nnet2/get_egs2.sh \
  #  data/tr05_multi_noisy exp/tri4a_dnn_tr05_multi_noisy_smbr_ali exp/tri4a_dnn_tr05_multi_noisy_smbr_egs2_2 #egs-dir

  # Usage: $0 [opts] <ali0> <egs0> <ali1> <egs1> ... <aliN-1> <egsN-1> <input-model> <exp-dir>
  steps/nnet2/train_multilang2_chime4.sh \
    exp/tri4a_dnn_tr05_multi_noisy_smbr_ali exp/tri4a_dnn_tr05_multi_noisy_smbr_egs2_2 exp/tri4a_dnn_tr05_multi_noisy_smbr_ali exp/tri4a_dnn_tr05_multi_noisy_smbr_egs2_2 exp/tri4a_dnn_tr05_multi_noisy_smbr_nnet2/final.mdl exp/tri5a_multilang

fi
