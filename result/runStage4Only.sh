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
stage=4 # resume training with --stage=N
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
chime4_data=/media/rezki/DATA2/dataset/CHiME3
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
# LM-rescoring experiment with 5-gram and RNN LMs
# It takes a few days to train a RNNLM.
enhancement_method=beamformit_5mics
enhancement_data=`pwd`/enhan/$enhancement_method
if [ $stage -le 4 ]; then
  if $flatstart; then
    local/run_lmrescore2.sh $chime4_data $enhancement_method
    # local/run_lmrescore3.sh $chime4_data $enhancement_method
  else
    local/run_lmrescore_recog.sh $enhancement_method $modeldir
  fi
fi

echo "Done."
