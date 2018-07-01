#!/bin/bash
# Author : Rezki Trianto

# Config:
hidden=300 # Num-hidden units
class=200 # Num-classes
lstmlm_ver=theanolm # version of TheanoLM to use
threads=1 # for LSTMLM-HS
bptt=4 # length of BPTT unfolding in LSTMLM
bptt_block=10 # length of BPTT unfolding in LSTMLM

. utils/parse_options.sh || exit 1;

. ./path.sh
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

if [ $# -ne 1 ]; then
  printf "\nUSAGE: %s <Chime4 root directory>\n\n" `basename $0`
  echo "Please specifies a Chime4 root directory"
  echo "If you use kaldi scripts distributed in the Chime4 data,"
  echo "It would be `pwd`/../.."
  exit 1;
fi

# check data directories
chime4_data=$1
wsj0_data=$chime4_data/data/WSJ0 # directory of WSJ0 in Chime4. You can also specify your WSJ0 corpus directory
if [ ! -d $chime4_data ]; then
  echo "$chime4_data does not exist. Please specify chime4 data root correctly" && exit 1
fi
if [ ! -d $wsj0_data ]; then
  echo "$wsj0_data does not exist. Please specify WSJ0 corpus directory" && exit 1
fi
lm_train=$wsj0_data/wsj0/doc/lng_modl/lm_train/np_data

# lm directories
dir=data/local/local_lm
srcdir=data/local/nist_lm
mkdir -p $dir

# extract 5k vocabulary from a baseline language model
srclm=$srcdir/lm_tgpr_5k.arpa.gz
if [ -f $srclm ]; then
  echo "Getting vocabulary from a baseline language model";
  gunzip -c $srclm | awk 'BEGIN{unig=0}{
    if(unig==0){
      if($1=="\\1-grams:"){unig=1}}
    else {
      if ($1 != "") {
        if ($1=="\\2-grams:" || $1=="\\end\\") {exit}
        else {print $2}}
    }}' | sed "s/<UNK>/<LSTM_UNK>/" > $dir/vocab_5k.lstm
else
  echo "Language model $srclm does not exist" && exit 1;
fi

# collect training data from WSJ0
touch $dir/train.lstm
if [ `du -m $dir/train.lstm | cut -f 1` -eq 223 ]; then
  echo "Not getting training data again [already exists]";
else
  echo "Collecting training data from $lm_train";
  gunzip -c $lm_train/{87,88,89}/*.z \
   | awk -v voc=$dir/vocab_5k.lstm '
   BEGIN{ while((getline<voc)>0) { invoc[$1]=1; }}
   /^</{next}{
     for (x=1;x<=NF;x++) {
       w=toupper($x);
       if (invoc[w]) { printf("%s ",w); } else { printf("<LSTM_UNK> "); }
     }
     printf("\n");
   }' > $dir/train.lstm
fi

# get validation data from Chime4 dev set
touch $dir/valid.lstm
if [ `cat $dir/valid.lstm | wc -w` -eq 54239 ]; then
  echo "Not getting validation data again [already exists]";
else
  echo "Collecting validation data from $chime4_data/data/transcriptions";
  cut -d" " -f2- $chime4_data/data/transcriptions/dt05_real.trn_all \
                 $chime4_data/data/transcriptions/dt05_simu.trn_all \
      > $dir/valid.lstm
fi

#=========================================================================== Author : Rezki T.
# check availability of TheanoLM for LSTMLM
$KALDI_ROOT/tools/extras/check_for_theanolm.sh "$lstmlm_ver" || exit 1

# train a LSTM language model
lstmmodel=$dir/lstmlm_5k_h${hidden}_bptt${bptt}
if [ -f $lstmmodel ]; then
  echo "A LSTM language model aready exists and is not constructed again"
  echo "To reconstruct, remove $lstmmodel first"
else
  echo "Training a LSTM language model with $lstmlm_ver"
  echo "(runtime log is written to $dir/lstmlm.log)"
  mkdir -p $dir/trainlstmResult
  #with vocabulary
#  $train_cmd $dir/lstmlm.log \
#   $KALDI_ROOT/tools/$lstmlm_ver/bin/theanolm train $dir/trainlstmResult/model.h5 $dir/valid.lstm \
#		--training-set $dir/train.lstm --vocabulary $dir/vocab_5k.lstm --vocabulary-format srilm-classes
	
   $train_cmd $dir/lstmlm.log \
    $KALDI_ROOT/tools/$lstmlm_ver/bin/theanolm train $dir/trainlstmResult/model.h5 $dir/valid.lstm \
		--training-set $dir/train.lstm --batch-size 256
  #ref from rnnlm training simple example
  # time $rnnpath/rnnlm -train $trainfile -valid $validfile -rnnlm $rnnmodel \
#		-hidden $hidden_size -rand-seed 1 -debug 2 \
#		-class $class_size -bptt $bptt_steps -bptt-block 10
   
  #ref. from chime4 rnnlm training
  #$train_cmd $dir/lstmlm.log \
 #  $KALDI_ROOT/tools/$lstmlm_ver/bin/theanolm train $dir/train.lstm -valid $dir/valid.lstm \
 #       -lstmlm $rlstmmodel -hidden $hidden -class $class \
 #       -rand-seed 1 -independent -debug 1 -bptt $bptt -bptt-block $bptt_block || exit 1;
fi

# store in a LSTMLM directory with necessary files
lstmdir=data/lang_test_lstmlm_5k_h${hidden}
mkdir -p $lstmdir
cp $lstmmodel $lstmdir/lstmlm
grep -v -e "<s>" -e "</s>" $dir/vocab_5k.lstm > $lstmdir/wordlist.lstm
touch $lstmdir/unk.probs # make an empty file because we don't know unk-word probs.

