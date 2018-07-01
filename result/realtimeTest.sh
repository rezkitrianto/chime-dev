#!/bin/bash

#@rezkitrianto

FILENAME="onlineWav.wav"
echo "Record audio"
echo "---------------------------"
read -p "Press enter when you're ready to record" rec
if [ -z $rec ]; then
  arecord -r 16000 -f S16_LE $FILENAME -d 1
fi
echo Request "file" $FILENAME created:

echo "Utterance text: "
read utterance

local/onlineDecode.sh --stage 0 $FILENAME $utterance

# echo "File path: "
# read filepath
# echo "Filepath input: $filepath"
# echo "Utterance text: "
# read utterance
# echo "Utterance input: $utterance"
#
# enhan=noisy
# local/onlineDecode.sh --stage 0 $filepath $utterance

# echo "result:"
# echo "WER:"
