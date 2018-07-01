#!/bin/bash

#@rezkitrianto

echo "File path: "
read filepath
echo "Filepath input: $filepath"
echo "Utterance text: "
read utterance
echo "Utterance input: $utterance"

enhan=noisy
local/onlineDecode.sh --stage 0 "$filepath" "$utterance"

# echo "result:"
# echo "WER:"
