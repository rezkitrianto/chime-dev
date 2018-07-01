#!/bin/bash
set -e

# Copyright 2009-2012  Microsoft Corporation  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0.

# This is modified from the script in standard Kaldi recipe to account
# for the way the WSJ data is structured on the Edinburgh systems.
# - Arnab Ghoshal, 29/05/12

# Modified from the script for CHiME2 baseline
# Shinji Watanabe 02/13/2015

# Config:
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

if [ $# -ne 1 ]; then
  printf "\nUSAGE: %s <corpus-directory>\n\n" `basename $0`
  echo "The argument should be a the top-level Chime4 directory."
  echo "It is assumed that there will be a 'data' subdirectory"
  echo "within the top-level corpus directory."
  exit 1;
fi

echo "$0 $@"  # Print the command line for logging

audio_dir=$1/data/audio/16kHz/isolated
audio_dir_BLSTM_GEV=$1/data/audio/16kHz/export_BLSTM
audio_dir_keyword=$1/data/audio/16kHz/keyword
#audio_dir_gsc=$1/data/audio/16kHz/MVDR_GSC_omlsa_6ch_track
trans_dir=$1/data/transcriptions
annotation_dir=$1/data/annotations

echo "extract 5th channel (CH5.wav, the center bottom edge in the front of the tablet) for noisy data"

dir=`pwd`/data/local/data
lmdir=`pwd`/data/local/nist_lm
mkdir -p $dir $lmdir
local=`pwd`/local
utils=`pwd`/utils

. ./path.sh # Needed for KALDI_ROOT
export PATH=$PATH:$KALDI_ROOT/tools/irstlm/bin
sph2pipe=$KALDI_ROOT/tools/sph2pipe_v2.5/sph2pipe
if [ ! -x $sph2pipe ]; then
  echo "Could not find (or execute) the sph2pipe program at $sph2pipe";
  exit 1;
fi

if $eval_flag; then
list_set="tr05_simu_noisy dt05_simu_noisy et05_simu_noisy"
else
list_set="tr05_simu_noisy dt05_simu_noisy"
fi

cd $dir

find $audio_dir -name '*CH5.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy5.flist
find $audio_dir -name '*CH1.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy1.flist
#find $audio_dir -name '*CH2.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy2.flist
find $audio_dir -name '*CH3.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy3.flist
find $audio_dir -name '*CH4.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy4.flist
find $audio_dir -name '*CH6.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy6.flist
find $audio_dir_BLSTM_GEV -name '*.wav' | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_noisy7.flist
# find $audio_dir_keyword -name '*.wav' | grep 'tr05_' | sort -u > tr05_simu_noisy8.flist

find $audio_dir -name '*CH5.wav' | grep 'dt05_bus_simu\|dt05_caf_simu\|dt05_ped_simu\|dt05_str_simu' | sort -u > dt05_simu_noisy5.flist

if $eval_flag; then
find $audio_dir -name '*CH5.wav' | grep 'et05_bus_simu\|et05_caf_simu\|et05_ped_simu\|et05_str_simu' | sort -u > et05_simu_noisy5.flist
fi

# make a dot format from json annotation files
cp $trans_dir/dt05_simu.dot_all dt05_simu.dot
if $eval_flag; then
cp $trans_dir/et05_simu.dot_all et05_simu.dot
fi

# make a scp file from file list
# for x in $list_set; do
#     cat $x.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav.ids
#     paste -d" " ${x}_wav.ids $x.flist | sort -k 1 > ${x}_wav.scp
# done

# By: Rezki Trianto
for x in $list_set; do
    if [ $x = "tr05_simu_noisy" ]; then
      cat ${x}5.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav5.ids
      cat ${x}1.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav1.ids
     # cat ${x}2.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav2.ids
      cat ${x}3.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav3.ids
      cat ${x}4.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav4.ids
      cat ${x}6.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav6.ids
      cat ${x}7.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav7.ids
      # cat ${x}8.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav8.ids
      paste -d" \n \n \n \n \n" ${x}_wav5.ids ${x}5.flist \
                        ${x}_wav1.ids ${x}1.flist \
                        ${x}_wav3.ids ${x}3.flist \
                        ${x}_wav4.ids ${x}4.flist \
                        ${x}_wav6.ids ${x}6.flist \
                        ${x}_wav7.ids ${x}7.flist | sort -k 1 > ${x}_wav.scp

      # paste -d" \n \n \n \n \n" ${x}_wav5.ids ${x}5.flist \
      #                   ${x}_wav1.ids ${x}1.flist \
      #                   ${x}_wav3.ids ${x}3.flist \
      #                   ${x}_wav4.ids ${x}4.flist \
      #                   ${x}_wav6.ids ${x}6.flist \
      #                   ${x}_wav7.ids ${x}7.flist \
                          # ${x}_wav8.ids ${x}8.flist | sort -k 1 > ${x}_wav.scp
    else
      cat ${x}5.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav.ids
      paste -d" " ${x}_wav.ids ${x}5.flist | sort -k 1 > ${x}_wav.scp
    fi
done

# make a transcription from dot
# simulation training data extract dot file from original WSJ0 data
# since it is generated from these data
if [ ! -e dot_files.flist ]; then
  echo "Could not find $dir/dot_files.flist files, first run local/clean_wsj0_data_prep.sh";
  exit 1;
fi
echo "TRACE - POS"
cat tr05_simu_noisy_wav.scp | awk -F'[_]' '{print $2}' | tr '[A-Z]' '[a-z]' \
    | $local/find_noisy_transcripts.pl dot_files.flist | cut -f 2- -d" " > tr05_simu_noisy.txt
cat tr05_simu_noisy_wav.scp | cut -f 1 -d" " > tr05_simu_noisy.ids
paste -d" " tr05_simu_noisy.ids tr05_simu_noisy.txt | sort -k 1 > tr05_simu_noisy.trans1

# dt05 and et05 simulation data are generated from the CHiME4 booth recording
# and we use CHiME4 dot files

cat dt05_simu.dot | sed -e 's/(\(.*\))/\1/' | awk '{print $NF ".CH5_SIMU"}'> dt05_simu_noisy.ids
cat dt05_simu.dot | sed -e 's/(.*)//' > dt05_simu_noisy.txt
paste -d" " dt05_simu_noisy.ids dt05_simu_noisy.txt | sort -k 1 > dt05_simu_noisy.trans1

if $eval_flag; then
cat et05_simu.dot | sed -e 's/(\(.*\))/\1/' | awk '{print $NF ".CH5_SIMU"}'> et05_simu_noisy.ids
cat et05_simu.dot | sed -e 's/(.*)//' > et05_simu_noisy.txt
paste -d" " et05_simu_noisy.ids et05_simu_noisy.txt | sort -k 1 > et05_simu_noisy.trans1
fi

# Do some basic normalization steps.  At this point we don't remove OOVs--
# that will be done inside the training scripts, as we'd like to make the
# data-preparation stage independent of the specific lexicon used.
noiseword="<NOISE>";
for x in $list_set;do
  cat $x.trans1 | $local/normalize_transcript.pl $noiseword \
    | sort > $x.txt || exit 1;
done
echo "TRACE - POS"
# Make the utt2spk and spk2utt files.
for x in $list_set; do
  cat ${x}_wav.scp | awk -F'_' '{print $1}' > $x.spk
  cat ${x}_wav.scp | awk '{print $1}' > $x.utt
  paste -d" " $x.utt $x.spk > $x.utt2spk
  cat $x.utt2spk | $utils/utt2spk_to_spk2utt.pl > $x.spk2utt || exit 1;

  # Extracting segments file.
  cat ${x}_wav.scp | awk '{print $2}' > $x.fname

  cat ${x}_wav.scp | awk -F'_' '{print $1}' > $x.spk
  cat ${x}_wav.scp | awk -F'_' '{print $2}' > $x.wsj_name
  paste -d" " $x.spk $x.wsj_name > $x.spk_wsj

  IFS='_' read -r -a array <<< "${x}"
  is_train_set=${array[0]}
  is_real=${array[1]}

  startTime=
  endTime=

  while read p; do
    # echo $p
    IFS=' ' read -r -a loopArr <<< "${p}"
    spk=${loopArr[0]}
    wsj=${loopArr[1]}

    startTime+=$( jq -r -a ".[] | select((.wsj_name==\""${wsj}"\") and (.wavfile | startswith(\""${spk}"\"))) | .start" < ${annotation_dir}/${is_train_set}_${is_real}.json )
    endTime+=$( jq -r -a ".[] | select((.wsj_name==\""${wsj}"\") and (.wavfile | startswith(\""${spk}"\"))) | .end" < ${annotation_dir}/${is_train_set}_${is_real}.json )

    startTime+=$'\n'
    endTime+=$'\n'


  done <$x.spk_wsj
  echo "$startTime" > $x.startTime
  echo "$endTime" > $x.endTime

  paste -d" " $x.utt $x.fname $x.startTime $x.endTime > $x.segments
done

# copying data to data/...
for x in $list_set; do
  mkdir -p ../../$x
  cp ${x}_wav.scp ../../$x/wav.scp || exit 1;
  cp ${x}.txt     ../../$x/text    || exit 1;
  cp ${x}.spk2utt ../../$x/spk2utt || exit 1;
  cp ${x}.utt2spk ../../$x/utt2spk || exit 1;
  cp ${x}.segments ../../$x/segments || exit 1;
done

echo "Data preparation succeeded"
