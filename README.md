# ARM KWS Demo

This repository contains a demo of [Keyword spotting for Microcontrollers](https://github.com/ARM-software/ML-KWS-for-MCU.git).

This demo is based on the ARM KWS for MCU's [simple_test](https://github.com/ARM-software/ML-KWS-for-MCU/tree/master/Deployment/Examples/simple_test), but removed the dependencies of mbed and adapt to linux platform and other arm chips.

## Quick start

1. Install toolchains
2. Clone related repositories:
```
git clone https://github.com/JeffyCN/ARM-KWS-demo.git
git clone https://github.com/JeffyCN/ML-KWS-for-MCU.git
git clone https://github.com/JeffyCN/CMSIS_5.git -b master
```
3. Enter ARM-KWS-demo/ and build the demo with "make"
4. Run the generated "kws_test" on the device or use qemu-arm-static:
```
root@jeffy:/# kws_test
Detected right (99%)
```

## Build for MCU

To build this demo for MCU:
```
make clean && make CPU=m4
```

## Testing

### Simple test

Replace "test.wav" and run "./test.sh"

### Realtime test

Run "./realtime_test.sh" and feed audio data to .kws, for example:
```
dd if=test.wav bs=1 skip=44 of=.kws
```
Or
```
modprobe snd-aloop
arecord -t raw -r 16000 -f S16_LE -c 1 -D hw:CARD=Loopback,DEV=0 .kws&
aplay -D hw:CARD=Loopback,DEV=1 test.wav
```

## More details about the demo

This demo is running [ARM KWS](https://github.com/ARM-software/ML-KWS-for-MCU.git) on [specified wave data](Source/wav_data.h) with a pre-generated DS CNN [quantized weights](https://github.com/ARM-software/ML-KWS-for-MCU/blob/master/Deployment/Source/NN/DS_CNN/ds_cnn_weights.h).

The quantized weights is generated by [quant_test.py](https://github.com/ARM-software/ML-KWS-for-MCU/blob/master/quant_test.py) from [trained model](https://github.com/ARM-software/ML-KWS-for-MCU/blob/master/train_commands.txt) checkpoint.

More details about the quantized weights, please check [this article](https://developer.arm.com/solutions/machine-learning-on-arm/developer-material/how-to-guides/converting-a-neural-network-for-arm-cortex-m-with-cmsis-nn/quantization)

## Retraining

There're some handy scripts under KWS/(some of them comes from https://github.com/tpeet/ML-KWS-for-MCU).

The steps to retraining:
1. Goto KWS/
2. Modify params in common.sh
3. Tune hyper params with "./hyper_optimize.sh"
4. Apply best hyper params(recorded in the trials file) to common.sh
5. Run "./train.sh" to train
6. Run "./test.sh" to check the accuracy
7. Run "./fold_batchnorm.sh" to fuse batch-norm layers
8. Run "./quant_dump.sh" to quantize and dump params

NOTE:
1. Step 3 and 4 can be skipped if you think the current hyper params is ok.
2. Step 3 is an indefinitely loop, can be terminated anytime.
3. Step 5 can take a very long time, can interrupt it when the accuracy becomes stable.
