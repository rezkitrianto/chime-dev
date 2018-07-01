#!/bin/bash

#confidence measures
plpp=0
numOfPhonemes=0
numOfStates=0
durations=0
totalDurationWUW=0

threshold1=0
threshold2=0
threshold3=0
threshold4=0
threshold5=0
threshold6=0

if [[ plpp < threshold1 ]];
  then
    echo "Non WUW"
    exit 1
  else
    if [[ numOfPhones > threshold2 ]];
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
                    train_file=trainFile.txt
                    model_dir=mod.model
                    svm-train -s 0 -t 0 $train_file $model_dir
                fi
            fi
        fi
    fi
  #statements
fi
