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


chime4_data=`pwd`/../..

chime4_data=/media/rezki/DATA2/dataset/CHiME3
modeldir=$chime4_data/tools/ASR_models
enhancement_method=beamformit_5mics
enhancement_data=`pwd`/enhan/$enhancement_method

nj=4
nj=3
case_insensitive=false
my_rttm_file=/home/rezki/Desktop/kws_word_list/extracted/rttm
my_ecf_file=/home/rezki/Desktop/kws_word_list/extracted/ecf.xml
my_kwlist_file=/home/rezki/Desktop/kws_word_list/extracted/kwlist.xml
dataset_dir=data-fmllr-tri3b/et05_real_beamformit_5mics

# ==================================KWS SETUP ==================================
# Usage: <ecf_file> <kwlist-file> [rttm-file] <lang-dir> <data-dir>
# local/kws/kws_setup.sh \
#   --case_insensitive $case_insensitive \
#   --rttm-file $my_rttm_file \
#   $my_ecf_file $my_kwlist_file data/lang $dataset_dir
# ==============================================================================

# ================================== KWS PROXY OOV =============================
#Generate the confusion matrix
#nb, this has to be done only once, as it is training corpora dependent,
#instead of search collection dependent

# Usage $0 [options] <data-dir> <model-dir> <ali-dir> <decode-dir> <out-dir>
if [ ! -f exp/conf_matrix/.done ] ; then
  local/kws/generate_confusion_matrix.sh --cmd "$decode_cmd" --nj $nj  \
    exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_ali exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4  exp/conf_matrix
  touch exp/conf_matrix/.done
fi
confusion=exp/conf_matrix/confusions.txt

# Usage: $0 [options] <lexicon-in> <work-dir>
if [ ! -f exp/g2p/.done ] ; then
  local/kws/train_g2p.sh  data/local/dict/lexicon.txt exp/g2p
  touch exp/g2p/.done
fi

# g2p_nbest=
# g2p_mass=
# kwsdatadir=$dataset_dir
# # Usage: $0 [options] <word-list> <g2p-model-dir> <output-dir>
# local/kws/apply_g2p.sh --nj $nj --cmd "$decode_cmd" \
#   --var-counts $g2p_nbest --var-mass $g2p_mass \
#   $kwsdatadir/oov.txt exp/g2p $kwsdatadir/g2p
# L2_lex=$kwsdatadir/g2p/lexicon.lex
#
# #
# L1_lex=data/local/lexiconp.txt
# local/kws/kws_data_prep_proxy.sh \
#   --cmd "$decode_cmd" --nj $nj \
#   --case-insensitive true \
#   --confusion-matrix $confusion \
#   --phone-cutoff $phone_cutoff \
#   --pron-probs true --beam $beam --nbest $nbest \
#   --phone-beam $phone_beam --phone-nbest $phone_nbest \
#   data/lang  $data_dir $L1_lex $L2_lex $kwsdatadir
# ==============================================================================

# ================================== KWS SEARCH ================================
max_states=150000
min_lmwt=7
max_lmwt=17
skip_scoring=false
decode_dir=exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_et05_real_beamformit_5mics_it4_
lang_dir=data/lang
data_dir=$dataset_dir

# Usage: $(basename $0) <lang-dir> <data-dir> <decode-dir>
local/kws/kws_search.sh --cmd "$decode_cmd" \
  --max-states ${max_states} --min-lmwt ${min_lmwt} \
  --max-lmwt ${max_lmwt} --skip-scoring $skip_scoring \
  --indices-dir $decode_dir/kws_indices $lang_dir $data_dir $decode_dir
# ==============================================================================

# ======================= KWS SEARCH WITH PROXY ================================
# kws search with proxy
# local/kws_search.sh --cmd "$cmd" --extraid $extraid  \
#   --max-states ${max_states} --min-lmwt ${min_lmwt} \
#   --max-lmwt ${max_lmwt} --skip-scoring $skip_scoring \
#   --indices-dir $decode_dir/kws_indices $lang_dir $data_dir $decode_dir
# ==============================================================================

echo "Everything looking good...."
exit 0
