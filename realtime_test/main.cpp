/*
 * Copyright (C) 2018 Arm Limited or its affiliates. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Description: Example code for running keyword spotting
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "kws_ds_cnn.h"

// Input audio channels
#ifndef CHANNELS
#define CHANNELS 1
#endif

// Handle half complete irq
#define DOUBLE_BUFFER 0

#define MAX_CLASS_LEN 8
#define OUTPUT_CLASSES { "Silence", "Unknown","yes","no","up","down","left","right","on","off","stop","go" }

KWS_DS_CNN *kws;
int16_t *audio_buffer_in;

// Tune the following three parameters to improve the detection accuracy
//  and reduce false positives
// Longer averaging window and higher threshold reduce false positives
//  but increase detection latency and reduce true positive detections.

// (recording_win*frame_shift) is the actual recording window size
//#define RECORDING_WIN 10

// Averaging window for smoothing out the output predictions
#define AVERAGING_WINDOW_LEN 3

// Should not be larger than NUM_FRAMES
#ifdef RECORDING_WIN
int recording_win = RECORDING_WIN;
#else
int recording_win = (NUM_FRAMES / 5);
#endif

// Should not be larger than (NUM_FRAMES / recording_win)
#ifdef AVERAGING_WINDOW_LEN
int averaging_window_len = AVERAGING_WINDOW_LEN;
#else
int averaging_window_len = (NUM_FRAMES / recording_win);
#endif

int detection_threshold = 90;  //in percent

void run_kws();
#undef __WFI
void __WFI();
void BSP_AUDIO_IN_TransferComplete_CallBack(void);
void BSP_AUDIO_IN_HalfTransfer_CallBack(void);

char *expect_class = NULL;
int main(int args, char**argv)
{
  kws = new KWS_DS_CNN(recording_win,averaging_window_len);

  kws->audio_buffer = new int16_t[kws->audio_buffer_size];

  audio_buffer_in = new int16_t[kws->audio_block_size * CHANNELS * (1 + DOUBLE_BUFFER)];

  printf("Start reading input wave...\n");

  if (args > 1) {
    expect_class = argv[1];
    printf("expect: %s\n", expect_class);
  }

  while (1) {
  /* A dummy loop to wait for the interrupts. Feature extraction and
     neural network inference are done in the interrupt service routine. */
    __WFI();
  }

  return 0;
}

/*
 * The audio recording works with two ping-pong buffers.
 * The data for each window will be tranfered by the DMA, which sends
 * sends an interrupt after the transfer is completed.
 */

// Manages the DMA Transfer complete interrupt.
void BSP_AUDIO_IN_TransferComplete_CallBack(void)
{
  if(kws->frame_len != kws->frame_shift) {
    //copy the last (frame_len - frame_shift) audio data to the start
    arm_copy_q7((q7_t *)(kws->audio_buffer)+2*(kws->audio_buffer_size-(kws->frame_len-kws->frame_shift)), (q7_t *)kws->audio_buffer, 2*(kws->frame_len-kws->frame_shift));
  }
  // copy the new recording data
  for (int i=0;i<kws->audio_block_size;i++) {
    kws->audio_buffer[kws->frame_len-kws->frame_shift+i] = audio_buffer_in[i * CHANNELS + DOUBLE_BUFFER * CHANNELS * kws->audio_block_size];
  }
  run_kws();
  return;
}

#if DOUBLE_BUFFER
// Manages the DMA Half Transfer complete interrupt.
void BSP_AUDIO_IN_HalfTransfer_CallBack(void)
{
  if(kws->frame_len!=kws->frame_shift) {
    //copy the last (frame_len - frame_shift) audio data to the start
    arm_copy_q7((q7_t *)(kws->audio_buffer)+2*(kws->audio_buffer_size-(kws->frame_len-kws->frame_shift)), (q7_t *)kws->audio_buffer, 2*(kws->frame_len-kws->frame_shift));
  }
  // copy the new recording data
  for (int i=0;i<kws->audio_block_size;i++) {
    kws->audio_buffer[kws->frame_len-kws->frame_shift+i] = audio_buffer_in[i * CHANNELS];
  }
  run_kws();
  return;
}
#endif

void run_kws()
{
  char output_class[][MAX_CLASS_LEN] = OUTPUT_CLASSES;

  kws->extract_features();    //extract mfcc features
  kws->classify();        //classify using dnn
  kws->average_predictions();

  int max_ind = kws->get_top_class(kws->averaged_output);
  if(kws->averaged_output[max_ind]>detection_threshold*128/100) {
    printf("%d%% %s\n",((int)kws->averaged_output[max_ind]*100/128),output_class[max_ind]);
    if (expect_class && strcmp(expect_class, output_class[max_ind]))
      printf("Wrong! expect: %s\n", expect_class);
  }
}

// HACK: fake wfi and read wave data from stdin
void __WFI()
{
  int size, remain, ret;

#if DOUBLE_BUFFER
  int hf_complete = 0;
#endif

  size = kws->audio_block_size * CHANNELS;

  remain = size * sizeof(int16_t);
  while(remain) {
    ret = read(0, (char *)audio_buffer_in + size * sizeof(int16_t) - remain, remain);

    if (ret < 0)
      exit(-1);

#if DOUBLE_BUFFER
    if (remain < size && !hf_complete) {
      hf_complete = 1;
      BSP_AUDIO_IN_HalfTransfer_CallBack();
    }
#endif

    if (!ret) {
      // Fill the remain spaces with silence
      memset((char *)audio_buffer_in + size * sizeof(int16_t) - remain, 0, remain);
      usleep(remain * 1000.0 / sizeof(int16_t) / 16.0 / CHANNELS);
      break;
    }

    remain -= ret;
  }

  BSP_AUDIO_IN_TransferComplete_CallBack();
}
