#!/bin/bash

. ./KWS/common.sh 2>/dev/null

MAX_CLASS_LEN=8
for word in $(echo $WANTED_WORDS | tr , ' '); do
  LEN=$(echo $word | wc -c)
  [ $(($LEN + 1)) -gt $MAX_CLASS_LEN ] && MAX_CLASS_LEN=$(($LEN + 1))
done

OUTPUT_CLASSES=$(echo "Silence,Unknown,$WANTED_WORDS"|sed "s/\b/\"/g")

sed -i "s/\(#define MAX_CLASS_LEN \).*/\1$MAX_CLASS_LEN/" $SOURCE_FILE
sed -i "s/\(#define OUTPUT_CLASSES \).*/\1{ $OUTPUT_CLASSES }/" $SOURCE_FILE
