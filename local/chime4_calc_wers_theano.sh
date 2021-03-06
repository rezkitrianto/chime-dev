#!/bin/bash

#  Copyright  2015  Mitsubishi Electric Research Laboratories (Author: Shinji Watanabe)
#  Apache 2.0.

set -e

# Config:
eval_flag=true # make it true when the evaluation data are released

. utils/parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  printf "\nUSAGE: %s <training experiment directory> <enhancement method> <graph_dir>\n\n" `basename $0`
  printf "%s exp/tri3b_tr05_sr_noisy noisy exp/tri4a_dnn_tr05_sr_noisy/graph_tgpr_5k\n\n" `basename $0`
  exit 1;
fi

echo "$0 $@"  # Print the command line for logging

. path.sh

dir=$1
enhan=$2
graph_dir=$3
weight=1.0
addDir="nnlm_weight_$weight"

echo "compute dt05 WER for each location"
echo ""
mkdir -p $dir/log
for a in `find $dir/decode_dt05_real_$enhan/$addDir/ | grep "\/wer_" | awk -F'[/]' '{print $NF}' | sort`; do
    echo -n "$a "
    if [ -e $dir/decode_dt05_simu_$enhan/$addDir ]; then
	cat $dir/decode_dt05_{real,simu}_$enhan/$addDir/$a | grep WER | awk '{err+=$4} {wrd+=$6} END{printf("%.2f\n",err/wrd*100)}'
    else
	cat $dir/decode_dt05_real_$enhan/$addDir/$a | grep WER | awk '{err+=$4} {wrd+=$6} END{printf("%.2f\n",err/wrd*100)}'
    fi
done | sort -n -k 2 | head -n 1 > $dir/log/best_wer_$enhan

lmw=`cut -f 1 -d" " $dir/log/best_wer_$enhan | cut -f 2 -d"_"`
echo "-------------------"
printf "best overall dt05 WER %s" `cut -f 2 -d" " $dir/log/best_wer_$enhan`
echo -n "%"
printf " (language model weight = %s)\n" $lmw
echo "-------------------"
if $eval_flag; then
  tasks="dt05 et05"
else
  tasks="dt05"
fi
for e_d in $tasks; do
  for task in simu real; do
    rdir=$dir/decode_${e_d}_${task}_$enhan
    if [ -e $rdir/$addDir ]; then
      for a in _BUS _CAF _PED _STR; do
	grep $a $rdir/$addDir/scoring/test_filt.txt \
	  > $rdir/$addDir/scoring/test_filt_$a.txt
	cat $rdir/$addDir/scoring/$lmw.tra \
	  | utils/int2sym.pl -f 2- $graph_dir/words.txt \
	  | sed s:\<UNK\>::g \
	  | compute-wer --text --mode=present ark:$rdir/$addDir/scoring/test_filt_$a.txt ark,p:- \
	  1> $rdir/$addDir/${a}_wer_$lmw 2> /dev/null
      done
    echo -n "${e_d}_${task} WER: `grep WER $rdir/$addDir/wer_$lmw | cut -f 2 -d" "`% (Average), "
    echo -n "`grep WER $rdir/$addDir/_BUS_wer_$lmw | cut -f 2 -d" "`% (BUS), "
    echo -n "`grep WER $rdir/$addDir/_CAF_wer_$lmw | cut -f 2 -d" "`% (CAFE), "
    echo -n "`grep WER $rdir/$addDir/_PED_wer_$lmw | cut -f 2 -d" "`% (PEDESTRIAN), "
    echo -n "`grep WER $rdir/$addDir/_STR_wer_$lmw | cut -f 2 -d" "`% (STREET)"
    echo ""
    echo "-------------------"
    fi
  done
done
echo ""
exit 1
for e_d in $tasks; do
  echo "-----------------------------"
  echo "1-best transcription for $e_d"
  echo "-----------------------------"
  for task in simu real; do
    rdir=$dir/decode_${e_d}_${task}_$enhan
    cat $rdir/$addDir/scoring/$lmw.tra \
      | utils/int2sym.pl -f 2- $graph_dir/words.txt \
      | sed s:\<UNK\>::g
  done
done
