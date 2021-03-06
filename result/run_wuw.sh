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

#=======================================INITIALIZATION END

rec_dir_train_keyword="/media/rezki/DATA2/dataset/wuw_dataset/train/1/conv"
rec_dir_train_nonkeyword="/media/rezki/DATA2/dataset/wuw_dataset/train/0/conv"
rec_dir_test_keyword="/media/rezki/DATA2/dataset/wuw_dataset/test/1/conv"
rec_dir_test_nonkeyword="/media/rezki/DATA2/dataset/wuw_dataset/test/0/conv"


# for i in ${rec_dir_train_keyword}
# do
#   declare -i a
#   a=1
#   for j in ${i}/*wav
#   do
#     utterance="test"
#     #decode the wav file and copy to the wuw directory
#     local/onlineDecode.sh --stage 0 "$j" "$utterance"
#     cp exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTest_real2_it4_v3/lat.1.gz wuw_lattices/train/1/lat."$a".gz
#     a=a+1
#     # echo $j
#   done
# done

# for i in ${rec_dir_train_nonkeyword}
# do
#   declare -i a
#   a=1
#   for j in ${i}/*wav
#   do
#     utterance="test"
#     #decode the wav file and copy to the wuw directory
#     local/onlineDecode.sh --stage 0 "$j" "$utterance"
#     cp exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTest_real2_it4_v3/lat.1.gz wuw_lattices/train/0/lat."$a".gz
#     a=a+1
#     # echo $j
#   done
# done

# for i in ${rec_dir_test_keyword}
# do
#   declare -i a
#   a=1
#   for j in ${i}/*wav
#   do
#     utterance="test"
#     #decode the wav file and copy to the wuw directory
#     local/onlineDecode.sh --stage 0 "$j" "$utterance"
#     cp exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTest_real2_it4_v3/lat.1.gz wuw_lattices/test/1/lat."$a".gz
#     a=a+1
#     # echo $j
#   done
# done

# for i in ${rec_dir_test_nonkeyword}
# do
#   declare -i a
#   a=1
#   for j in ${i}/*wav
#   do
#     utterance="test"
#     #decode the wav file and copy to the wuw directory
#     local/onlineDecode.sh --stage 0 "$j" "$utterance"
#     cp exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTest_real2_it4_v3/lat.1.gz wuw_lattices/test/0/lat."$a".gz
#     a=a+1
#     # echo $j
#   done
# done

# exit 1
#=======================================DECODE END


lat_dir_train_keyword="wuw_lattices/train/1"
lat_dir_train_nonkeyword="wuw_lattices/train/1"
lat_dir_test_keyword="wuw_lattices/test/1"
lat_dir_test_nonkeyword="wuw_lattices/test/1"

for i in ${lat_dir_train_keyword}
do
  declare -i a
  a=1
  for j in ${i}/*gz
  do
    #----------------------DURATION
    /home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones --replace-output-symbols=true /home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2/final.mdl "ark:gunzip -c $j|" ark:phone_aligned"$a".lats
    lattice-1best ark:phone_aligned100.lats ark:- | nbest-to-ctm ark:- "$a".ctm

    # #get duration
    cat "$a".ctm | awk -F' ' '{print $4}' > wuw_cm/train/1/lat_"$a".dur

    #get sum of duration
    awk '{s+=$1} END {print s}' wuw_cm/train/1/lat_"$a".dur > wuw_cm/train/1/lat_"$a".alldur

    #get normalized-duration
    latalldur=`(cat wuw_cm/train/1/lat_"$a".alldur)`
    awk -v c=$latalldur '{ print $1/c }' wuw_cm/train/1/lat_"$a".dur > wuw_cm/train/1/lat_"$a".norm

    #========================LOG-LIKELIHOOD
    indir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTestWuw1ch_it4_v2_grammar2
    oldlm=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_wuw/G.fst
    oldlmcommand="fstproject --project_output=true $oldlm |"

    /home/rezki/sandbox/kaldi/src/latbin/lattice-1best --acoustic-scale=0.1 "ark:gunzip -c $indir/lat.1.gz|" ark:1best.lats
    /home/rezki/sandbox/kaldi/src/latbin/lattice-lmrescore2 --lm-scale=-1.0 "ark:1best.lats" "$oldlmcommand" "ark,t:|gzip -c>$indir/lat.out.gz"

    #read feature duration and ac. costs to become feature


    a=a+1
  done
done

exit 1

#==================================================single-utterance only-obsolete

#generate feature for train
for i in {1..16}
do
   echo "Welcome $i times"
done

#extract feature for all the wav file in the directory
echo "=============================================================DECODE PROCESS START============================================================="
# # online decode by nnet2



# local/run_test.sh --stage 2

echo "=============================================================DECODE PROCESS END============================================================="

# generates phonemes from .mdl
# /home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones "ark:gunzip -c lat.1.gz|"
# exit 1

#another phoneme segmentation and durations
#generates phonemes
echo "=============================================================GET DURATION START============================================================="

/home/rezki/sandbox/kaldi/src/latbin/lattice-align-phones --replace-output-symbols=true /home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2/final.mdl "ark:gunzip -c lat.2.gz|" ark:phone_aligned100.lats
lattice-1best ark:phone_aligned100.lats ark:- | nbest-to-ctm ark:- 1aaa.ctm
# #get duration
cat 9.ctm | awk -F' ' '{print $4}' > wuw_cm/lat.dur
#get sum of duration
awk '{s+=$1} END {print s}' wuw_cm/lat.dur > wuw_cm/lat.alldur
#get normalized-duration
latalldur=`(cat wuw_cm/lat.alldur)`
awk -v c=$latalldur '{ print $1/c }' wuw_cm/lat.dur > wuw_cm/lat.norm
#                                        
# exit 1
echo "=============================================================GET DURATION END============================================================="

# 1.ctm format: <utterance-id> 1 <begin-time> <end-time> <word-id>
# ali-to-phones --ctm-output 1.mdl ark:1.ali 1.ctm
# phoneme duration * 10ms
# /home/rezki/sandbox/kaldi/src/bin/ali-to-phones --write-lengths=true --ctm-output 1.mdl ark:1.ali 1.ctm
# exit 1

#log-likelihood
echo "=============================================================GET LOG-LIKELIHOOD START============================================================="
# /home/rezki/sandbox/kaldi_52/src/latbin/lattice-1best --lm-scale=14.0 "ark:gunzip -c lat.1.gz|" ark:- | /home/rezki/sandbox/kaldi_52/src/latbin/nbest-to-linear ark:- ark,t:out.alignment ark,t:out.transcription ark,t:out.lm ark,t:out.am
# /home/rezki/sandbox/kaldi/src/latbin/lattice-to-post --lm-scale=14 "ark:gunzip -c lat.1.gz|" ark:- | /home/rezki/sandbox/kaldi/src/bin/post-to-phone-post ${mdl_nnet2}/final.mdl ark:- ark,t:phones.post
# nbest-to-linear
# /home/rezki/sandbox/kaldi/src/latbin/lattice-to-htk ark:phone_aligned900.lats lats9.slf
# /home/rezki/sandbox/kaldi_52/src/latbin/lattice-1best ark:phone_aligned9001.lats ark:- | /home/rezki/sandbox/kaldi/src/latbin/lattice-to-htk ark:- lats92.slf

# #get the log-likelihood from gmm-rescore-lattice -> done if use gmm model
# /home/rezki/sandbox/kaldi/src/gmmbin/gmm-rescore-lattice /home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats_nnet2/final.mdl ark:1.lats scp:trn.scp ark:2.lats

indir=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/exp/tri4a_dnn_tr05_multi_noisy_smbr_i1lats/decode_tgpr_5k_onlineTestWuw1ch_it4_v2_grammar2
oldlm=/home/rezki/sandbox/kaldi/egs/chime4DevFE1_allChannels3/s5_6ch/data/lang_test_wuw/G.fst
oldlmcommand="fstproject --project_output=true $oldlm |"

/home/rezki/sandbox/kaldi/src/latbin/lattice-1best --acoustic-scale=0.1 "ark:gunzip -c $indir/lat.1.gz|" ark:1best.lats
/home/rezki/sandbox/kaldi/src/latbin/lattice-lmrescore2 --lm-scale=-1.0 "ark:1best.lats" "$oldlmcommand" "ark,t:|gzip -c>$indir/lat.out.gz"  ark:1best.lats


# exit 1

logProbFile='wuw_cm/lat.ll'
filename="lats2.slf"
if [ ! -e "$logProbFile" ] ;
  then
    touch "$logProbFile"
    touch "$filename"
  else
    rm $logProbFile
    touch "$logProbFile"

    rm $filename
    touch "$filename"
fi

while read -r line
do
    ln="$line"
    if [[ $line == *"l="* ]]; then
      ll=`sed -e 's#.*=\(\)#\1#' <<< "$line"`
      echo "$ll" >> $logProbFile
    fi
done < "$filename"

# llnorm
awk -v c=$latalldur '{ print $1/c }' $logProbFile > wuw_cm/lat.llNorm

#llsum
awk '{s+=$1} END {print s}' wuw_cm/lat.ll > wuw_cm/lat.allll
latallll=`(cat wuw_cm/lat.allll)`

#ok
#pplp (ll/latallll)/dur
filename="lats2.slf"
while read -r line
do
    ln="$line"
    awk -v c=$latallll dur=ln '{ print ($1/c)/2 }' $logProbFile > wuw_cm/lat.pplp
done < "wuw_cm/lat.dur"
exit 1

echo "=============================================================GET LOG-LIKELIHOOD END============================================================="


#======================================================================
#doClassify
exit 1

#build feature vectors
train_file=/home/rezki/Desktop/svmmodel/trainFile.txt
model_dir=/home/rezki/Desktop/svmmodel/mod.model
svm-train -s 0 -t 0 $train_file $model_dir

test_file=/home/rezki/Desktop/svmmodel/testFile.txt
output_file=/home/rezki/Desktop/svmmodel/svmPredicted.result
svm-predict $test_file $model_dir $output_file

exit 1

plpp=0.6
numOfPhonesPLPP=4
numOfStates=1
durations-of-okay=0.1
totalDurationWUW=`(cat wuw_cm/lat.alldur)`

phonemeNum=8
threshold1=0.74
threshold2=3
threshold3=0
threshold4=0.3
threshold5=6*phonemeNum
threshold6=15*phonemeNum
#threshold5 and threshold6 is in ms

if [[ plpp < threshold1 ]];
  then
    echo "Non WUW"
    exit 1
  else
    if [[ numOfPhonesPLPP > threshold2 ]];
      then
        echo "Non WUW"
        exit 1
      else
        if [[ numOfStates > threshold3 ]];
          then
            echo "Non WUW"
            exit 1
          else
            if [[ durations < threshold4 ]];
              then
                echo "Non WUW"
                exit 1
              else
                if [[ totalDurationWUW < threshold5  ] && [ totalDurationWUW > threshold6  ]];
                  then
                    echo "Non WUW"
                    exit 1
                  else
                    echo "WUW candidates. run SVM"

                    #build feature vectors
                    train_file=/home/rezki/Desktop/svmmodel/trainFile.txt
                    model_dir=/home/rezki/Desktop/svmmodel/mod.model
                    # svm-train -s 0 -t 0 $train_file $model_dir

                    test_file=/home/rezki/Desktop/svmmodel/testFile.txt
                    output_file=/home/rezki/Desktop/svmmodel/svmPredicted.result
                    svm-predict $test_file $model_dir $output_file
                fi
            fi
        fi
    fi
  #statements
fi
