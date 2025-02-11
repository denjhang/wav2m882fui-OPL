# wav2m882fui-OPL
 The translated Wave MML program and the MML to furnace tracker instructment (.fui) conversion program in mgs format allow you to easily make the YM3526/3812/YMF262/278 (OPL Series) FM sound human voice on the Furnace.
 This program will perform Fourier transform on the waveform at 1/60 second intervals (optional precision) to obtain frequency and volume data,   
 and use 2 OPL channels to play sine waves simultaneously to play the human voice.   
 The best results will be obtained when you select 1/60 second.   

# Wave MML
https://mdpc.dousetsu.com/utility/msx/wave_mml.htm  
https://mdpc.dousetsu.com/other/tech/fm1ch.htm  
https://mdpc.dousetsu.com/utility/m88/wave_mml.htm  
https://mdpc.dousetsu.com/utility/midi/wave.htm  
https://mdpc.dousetsu.com/utility/midi/wave_gamma.htm  

![image](https://github.com/denjhang/wav2m882fui-OPL/blob/main/pics/wave_mml_m88.png)
![image](https://github.com/denjhang/wav2m882fui-OPL/blob/main/pics/make_m88.png)

# cc3.exe
This program can convert mucom88 mml text in mgs format into 2 OPL fui files. 

# Usage
1. First use something like Audacity to trim the audio. I don't recommend that the length of a single audio file exceed 5 seconds. Note that it must be a signed 44100Hz 16-bit wav file.   
2. Open wave_MML_M88-en.exe and convert the wav to an intermediate file dat. I recommend selecting 1/60 precision. This usually takes a few minutes.    
3. Open make_MML-en.exe and convert dat to txt. This will be completed quickly.  
4. Drag txt into run-cc-org.bat, and cc3.exe will automatically complete the conversion from txt to fui.  
5. Open Furnace Tracker, create a new YM3526/3812/YMF262/YMF278 music project, and then import all fui. Select opl-ch-1, -2 timbres one by one in the FM-1 and FM-2 channels in the pattern and enter "C-3", then press Enter, and you can hear the voice.  
6. Note that this usually requires placing different fui files on multiple channels at the same time to play the voice correctly. If the voice speed is too fast or too slow, please adjust the Base Tempo.   
