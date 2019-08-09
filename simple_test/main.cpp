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

#include "kws_ds_cnn.h"
#include "wav_data.h"

#define MAX_CLASS_LEN 8
#define OUTPUT_CLASSES { "Silence", "Unknown","yes","no","up","down","left","right","on","off","stop","go" }

int16_t audio_buffer[NUM_FRAMES*FRAME_SHIFT+FRAME_LEN-FRAME_SHIFT]=WAVE_DATA;

int main(int args, char**argv)
{
  char output_class[][MAX_CLASS_LEN] = OUTPUT_CLASSES;
  KWS_DS_CNN kws(audio_buffer);

  char *expect_class = NULL;
  if (args > 1) {
    expect_class = argv[1];
    printf("expect: %s\n", expect_class);
  }

  kws.extract_features();
  kws.classify();
  int max_ind = kws.get_top_class(kws.output);
  printf("Detected %s (%d%%)\r\n",output_class[max_ind],((int)kws.output[max_ind]*100/128));

  if (expect_class && strcmp(expect_class, output_class[max_ind]))
    printf("Wrong! expect: %s\n", expect_class);

  return 0;
}
