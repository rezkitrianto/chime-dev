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

rec_dir="/media/rezki/DATA2/dataset/test/English_Audio_Files/GEV/conv /media/rezki/DATA2/dataset/test/English_Audio_Files/unprocessed/conv /media/rezki/DATA2/dataset/test/English_Audio_Files/Usfita/conv"
for i in ${rec_dir}
do
  for j in ${i}/*wav
  do
    #decode the wav file and copy to the wuw directory
  done
done

#generate feature for train
for i in {1..16}
do
   echo "Welcome $i times"
done

#extract feature for all the wav file in the directory
echo "=============================================================DECODE PROCESS START============================================================="
# # online decode by nnet2
# /home/rezki/sandbox/kaldi/src/online2bin/online2-wav-nnet2-latgen-faster \
#   --do-endpointing=false \
#   --online=false \
#   --max-active=7000 \
#   --beam=15.0 \
#   --lattice-beam=6.0 \
#   --acoustic-scale=0.1 \
#   --config=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/conf/online_nnet2_decoding.conf \
#   --word-symbol-table=${graphdir2}/words.txt \
#   ${mdl_nnet2}/final.mdl ${graphdir2}/HCLG.fst "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 okgoogle16k.wav|" \
#   "ark:|gzip -c > lat.2.gz"
# exit 1

# # online decode by nnet3
#   /home/rezki/sandbox/kaldi_52/src/online2bin/online2-wav-nnet3-latgen-faster \
#     --do-endpointing=false \
#     --online=false \
#     --max-active=7000 \
#     --beam=15.0 \
#     --lattice-beam=6.0 \
#     --acoustic-scale=1.0 \
#     --config=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/chain/tdnn_blstm_1a_5layers_dropout1_sp_noIvector_online/conf/online.conf \
#     --word-symbol-table=${graphdir3}/words.txt \
#     ${mdl_nnet3}/final.mdl ${graphdir3}/HCLG.fst "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 okgoogle16k.wav|" \
#     "ark:|gzip -c > lat.3.gz"
# exit 1


# local/run_test.sh --stage 2

echo "=============================================================DECODE PROCESS END============================================================="

# generates phonemes from .mdl
# /home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones "ark:gunzip -c lat.1.gz|"
# exit 1

#another phoneme segmentation and durations
#generates phonemes
echo "=============================================================GET DURATION START============================================================="

# /home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones --replace-output-symbols=true ${mdl_nnet2}/final.mdl "ark:gunzip -c lat.2.gz|" ark:phone_aligned100.lats
/home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones --replace-output-symbols=true /home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2/final.mdl "ark:gunzip -c lat.2.gz|" ark:phone_aligned100.lats
# #get duration
cat 9.ctm | awk -F' ' '{print $4}' > wuw_cm/lat.dur
#get sum of duration
awk '{s+=$1} END {print s}' wuw_cm/lat.dur > wuw_cm/lat.alldur
latalldur=`(cat wuw_cm/lat.alldur)`
#get normalized-duration
awk -v c=$latalldur '{ print $1/c }' wuw_cm/lat.dur > wuw_cm/lat.norm
# 
