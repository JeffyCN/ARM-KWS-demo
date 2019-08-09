#!/bin/bash

TEST_AUDIO=./test.wav
SOURCE_FILE=./simple_test/main.cpp

. ./common.sh

python ./wav_dump.py --wav_file $TEST_AUDIO \
  && mv wav_data.h simple_test/ || exit

make -B -j 32 &>/tmp/kws_test.log || { cat /tmp/kws_test.log && exit; }

./kws_test
