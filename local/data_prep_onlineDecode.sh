#!/bin/bash
echo "TRACE TEST"
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

if [ $# -ne 2 ]; then
  printf "\nUSAGE: %s <corpus-directory>\n\n" `basename $0`
  echo "The argument should be a the top-level Chime4 directory."
  echo "It is assumed that there will be a 'data' subdirectory"
  echo "within the top-level corpus directory."
  exit 1;
fi

echo "$0 $@"  # Print the command line for logging

# audio_dir=$1/data/audio/16kHz/isolated
# audio_dir_BLSTM_GEV=$1/data/audio/16kHz/export_BLSTM
# audio_dir_gsc=$1/data/audio/16kHz/MVDR_GSC_omlsa_6ch_track
# audio_dir_test=/home/rezki/sandbox/BeamformIt/test
# audio_dir_test=/media/rezki/DATA2/dataset/test/wuw1ch/conv
# audio_dir_test=/media/rezki/DATA2/dataset/test/wuw1ch1
# trans_dir=$1/data/transcriptions
audio_dir_test="$1"
utterance_text="$2"
speaker=M01
# echo "extract 5th channel (CH5.wav, the center bottom edge in the front of the tablet) for noisy data"

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

cd $dir

# find $audio_dir_test -name '*.wav' | sort -u > onlineTest2.flist
echo $audio_dir_test > onlineTest2.flist

echo $utterance_text > onlineTest2.utt
echo $speaker > onlineTest2.spk

# make a scp file from file list
# Modified by: Rezki Trianto
# cat onlineTest.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav//' > onlineTest.ids
# paste -d" " onlineTest.ids onlineTest.flist | sort -k 1 > onlineTest_wav.scp

cat onlineTest2.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav//' > onlineTest2.ids
paste -d" " onlineTest2.ids onlineTest2.flist | sort -k 1 > onlineTest2_wav.scp
paste -d" " onlineTest2.ids onlineTest2.utt | sort -k 1 > onlineTest2.txt
paste -d" " onlineTest2.spk onlineTest2.ids | sort -k 1 > onlineTest2.spk2utt
paste -d" " onlineTest2.ids onlineTest2.spk | sort -k 1 > onlineTest2.utt2spk

# Do some basic normalization steps.  At this point we don't remove OOVs--
# that will be done inside the training scripts, as we'd like to make the
# data-preparation stage independent of the specific lexicon used.
# noiseword="<NOISE>";
# for x in $list_set;do
#   cat $x.trans1 | $local/normalize_transcript.pl $noiseword \
#     | sort > $x.txt || exit 1;
# done

# Make the utt2spk and spk2utt files.
# cat onlineTest_wav.scp | awk -F'_' '{print $1}' > onlineTest.spk
# cat onlineTest_wav.scp | awk '{print $1}' > onlineTest.utt
# paste -d" " onlineTest.utt onlineTest.spk > onlineTest.utt2spk
# cat onlineTest.utt2spk | $utils/utt2spk_to_spk2utt.pl > onlineTest.spk2utt || exit 1;



# copying data to data/...
mkdir -p ../../onlineTest_real2
cp onlineTest2_wav.scp ../../onlineTest_real2/wav.scp || exit 1;
cp onlineTest2.txt     ../../onlineTest_real2/text    || exit 1; # 6 ch total
cp onlineTest2.spk2utt ../../onlineTest_real2/spk2utt || exit 1;
cp onlineTest2.utt2spk ../../onlineTest_real2/utt2spk || exit 1;

echo "Data preparation succeeded"
