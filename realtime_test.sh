#!/bin/bash

TEST_AUDIO=./test.wav
SOURCE_FILE=./realtime_test/main.c

. ./common.sh

REALTIME=1 \
C_FLAGS="-DCHANNELS=1" \
make -B -j 32 &>/tmp/kws_realtime_test.log || { cat /tmp/kws_realtime_test.log && exit; }


killall kws_realtime_test &>/dev/null
rm -f .kws
mkfifo .kws

echo Run "dd if=<test wav file> bs=1 skip=44 of=.kws" to feed wave data
{
  sleep 1
  dd if=$TEST_AUDIO bs=1 skip=44 of=.kws 2>/dev/null
}&
./kws_realtime_test $1 < .kws
