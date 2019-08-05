#!/bin/bash

. ./KWS/common.sh 2>/dev/null

TEST_AUDIO=./test.wav
SOURCE_FILE=./Source/main.cpp

MAX_CLASS_LEN=8
for word in $(echo $WANTED_WORDS | tr , ' '); do
  LEN=$(echo $word | wc -c)
  [ $(($LEN + 1)) -gt $MAX_CLASS_LEN ] && MAX_CLASS_LEN=$(($LEN + 1))
done

OUTPUT_CLASSES=$(echo "Silence,Unknown,$WANTED_WORDS"|sed "s/\b/\"/g")

sed -i "s/\(#define MAX_CLASS_LEN \).*/\1$MAX_CLASS_LEN/" $SOURCE_FILE
sed -i "s/\(#define OUTPUT_CLASSES \).*/\1{ $OUTPUT_CLASSES }/" $SOURCE_FILE

python ./wav_dump.py --wav_file $TEST_AUDIO \
  && mv wav_data.h Source/ || exit

make -B -j 32 &>/tmp/kws_test.log || { cat /tmp/kws_test.log && exit; }

./kws_test
