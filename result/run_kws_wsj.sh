#!/bin/bash

# Kaldi ASR baseline for the CHiME-4 Challenge (6ch track: 6 channel track)
#
# Copyright 2016 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)
#  Modified by: rezkitrianto 2017

. ./path.sh
. ./cmd.sh

# Config:
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
# for d in $modeldir $modeldir/data/{lang,lang_test_tgpr_5k,lang_test_5gkn_5k,lang_test_rnnlm_5k_h300,local} \
#   $modeldir/exp/{tri3b_tr05_multi_noisy,tri4a_dnn_tr05_multi_noisy,tri4a_dnn_tr05_multi_noisy_smbr_i1lats}; do
#   [ ! -d ] && echo "$0: no such directory $d. specify models correctly or execute './run.sh --flatstart true' first" && exit 1;
# done
#####check data and model paths finished#######

enhancement_method=beamformit_5mics
enhancement_data=`pwd`/enhan/$enhancement_method
#####main program start################

duration=`feat-to-len scp:data-fmllr-tri3b/et05_real_beamformit_5mics/feats.scp  ark,t:- | awk '{x+=$2} END{print x/100;}'`
echo "duration : $duration"
#local/generate_example_kws.sh data-fmllr-tri3b/et05_real_beamformit_5mics/ data/kws_tr/ #hanya contoh kws. data kws sendiri bisa dibuat sendiri sesuai format. (bagaimana cara generate .fst jika data kws self-collected?)
#local/kws_data_prep.sh data/lang data-fmllr-tri3b/et05_real_beamformit_5mics/ data/kws_tr/ #

#steps/make_index.sh --cmd "$decode_cmd" --acwt 0.1 \
# data/kws_tr data/lang/ \
# exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/ \
# exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/kws_tr

#steps/search_index.sh --cmd "$decode_cmd" \
# data/kws_tr \
# exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/kws_tr

 # If you want to provide the start time for each utterance, you can use the --segments
 # option. In WSJ each file is an utterance, so we don't have to set the start time.
# cat exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/kws_tr/result.* | \
#  utils/write_kwslist.pl --flen=0.01 --duration=$duration \
#  --normalize=true --map-utter=data/kws/utter_map \
#  - exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/kws_tr/kwslist.xml

  extraid_flags=
  local/kws/kws_score.sh $extraid_flags data/ exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4/kws_
echo "Everything looking good...."
exit 0
