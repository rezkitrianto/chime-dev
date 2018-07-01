#!/bin/bash

echo "run wuw start"
# rzk=/home/rezki/sandbox/kaldi/
# server=/home/rezki/sandbox/kaldi/
graphdir2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_tgpr_5k
graphdir3=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector/graph_sw1_tg
# graphdir2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy/graph_wuw
# graphdir2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp/graph_sw1_tg
mdl_nnet2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2
mdl_nnet3=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector
# mdl_nnet2=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp

gmmdecDir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri3b_tr05_multi_noisy
decDir=/home/rezki/sandbox/kaldi/egs/voxforge/online_demo/work
#decode

# ===================== realtime decoding for all dir-file
rec_dir="/media/rezki/DATA2/dataset/test/English_Audio_Files/GEV/conv /media/rezki/DATA2/dataset/test/English_Audio_Files/unprocessed/conv /media/rezki/DATA2/dataset/test/English_Audio_Files/Usfita/conv"
# rec_dir="/media/rezki/DATA2/dataset/CHiME3/data/audio/16kHz/export_BLSTM/dt05_bus_real"
for i in ${rec_dir}
do
  for j in ${i}/*wav
  do
# /home/rezki/sandbox/kaldi/src/online2bin/online2-wav-nnet2-latgen-faster \
#   --do-endpointing=false \
#   --online=false \
#   --max-active=7000 \
#   --beam=15.0 \
#   --lattice-beam=6.0 \
#   --acoustic-scale=0.1 \
#   --config=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/conf/online_nnet2_decoding.conf \
#   --word-symbol-table=${graphdir2}/words.txt \
#   ${mdl_nnet2}/final.mdl ${graphdir2}/HCLG.fst "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 ${j}|" \
#   ark:/dev/null

  # /home/rezki/sandbox/kaldi_52/src/online2bin/online2-wav-nnet3-latgen-faster \
  #   --do-endpointing=false \
  #   --online=false \
  #   --max-active=7000 \
  #   --beam=15.0 \
  #   --lattice-beam=6.0 \
  #   --acoustic-scale=1.0 \
  #   --config=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector_online/conf/online.conf \
  #   --word-symbol-table=${graphdir3}/words.txt \
  #   ${mdl_nnet3}/final.mdl ${graphdir3}/HCLG.fst "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 ${j}|" \
  #   ark:/dev/null

  local/run_test.sh --stage 2
done
done
exit 1
