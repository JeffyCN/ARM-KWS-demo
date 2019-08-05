import argparse

import wave
import numpy as np

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--wav_file',
      type=str,
      # pylint: disable=line-too-long
      default='KWS/silence.wav',
      # pylint: enable=line-too-long
      help='Location of wav file.')

  FLAGS, unparsed = parser.parse_known_args()

  # Base on: https://github.com/ARM-software/ML-KWS-for-MCU/issues/21
  print('Converting {}'.format(FLAGS.wav_file))

  audio = wave.open(FLAGS.wav_file)
  signal = audio.readframes(-1)
  signal = np.fromstring(signal, 'Int16')

  f = open('wav_data.h', 'wb')
  f.close()
  with open("wav_data.h",'ab') as f:
    f.write("#define WAVE_DATA {")
    np.savetxt(f,signal,fmt="%d",delimiter=",",newline=",")
    f.write("}")
