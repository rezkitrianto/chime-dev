#!/bin/bash

# Copyright 2012 Vassil Panayotov
# Apache 2.0

# Note: you have to do 'make ext' in ../../../src/ before running this.

# Set the paths to the binaries and scripts needed
KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/../s5/utils/:$KALDI_ROOT/src/onlinebin:$KALDI_ROOT/src/bin:$PATH

# data_file="online-data"
# data_url="http://sourceforge.net/projects/kaldi/files/online-data.tar.bz2"
#
# # Change this to "tri2a" if you like to test using a ML-trained model
# ac_model_type=tri2b_mmi
#
# # Alignments and decoding results are saved in this directory(simulated decoding only)
# decode_dir="./work"
#
# . parse_options.sh
#
# ac_model=${data_file}/models/$ac_model_type
# trans_matrix=""
# audio=${data_file}/audio
#
# if [ ! -s ${data_file}.tar.bz2 ]; then
#     echo "Downloading test models and data ..."
#     wget -T 10 -t 3 $data_url;
#
#     if [ ! -s ${data_file}.tar.bz2 ]; then
#         echo "Download of $data_file has failed!"
#         exit 1
#     fi
# fi
#
# if [ ! -d $ac_model ]; then
#     echo "Extracting the models and data ..."
#     tar xf ${data_file}.tar.bz2
# fi
#
# if [ -s $ac_model/matrix ]; then
#     trans_matrix=$ac_model/matrix
# fi
#
# echo
# echo -e "  LIVE DEMO MODE - you can use a microphone and say something\n"
# echo "  The (bigram) language model used to build the decoding graph was"
# echo "  estimated on an audio book's text. The text in question is"
# echo "  \"King Solomon's Mines\" (http://www.gutenberg.org/ebooks/2166)."
# echo "  You may want to read some sentences from this book first ..."
# echo
# online-gmm-decode-faster --rt-min=0.5 --rt-max=0.7 --max-active=4000 \
#    --beam=12.0 --acoustic-scale=0.0769 $ac_model/model $ac_model/HCLG.fst \
#    $ac_model/words.txt '1:2:3:4:5' $trans_matrix;;

graphdir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k
mdl_nnet2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2
  # --config=nnet_a_online/conf/online_nnet2_decoding.conf \

# /home/rezki/sandbox/kaldi/src/online2bin/online2-wav-nnet2-latgen-faster \
#   --do-endpointing=false \
#   --online=false \
#   --max-active=7000 \
#   --beam=15.0 \
#   --lattice-beam=6.0 \
#   --acoustic-scale=0.1 \
#   --word-symbol-table=${graphdir}/words.txt \
#   ${mdl_nnet2}/final.mdl ${graphdir}/HCLG.fst "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 cut.wav|" \
#   ark:/dev/null
