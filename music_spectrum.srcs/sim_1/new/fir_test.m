close all; clear all;
rng default;
K=1024;
fs=24000;
t=0:1/fs:(K-1)/fs;
f1=900;
f2=3000;
f3=6000;
s=10000*(cos(2*pi*f1*t)+cos(2*pi*f2*t)+cos(2*pi*f3*t));
figure(1);
% signal_frequencyspectrum(s,fs);
grid on;
xlabel('Frequency/Hz');ylabel('Amplitude/dB');
 
%%%%%%%%%%%%%%%%%%%%%%%%% FIR低通滤波 %%%%%%%%%%%%%%%%%%%%%%%%%
lowpass_Fs=fs;            % 低通滤波器的采样频率
lowpass_Fpass=1000;   % 低通滤波器的通带截止频率
lowpass_Fstop=2000;   % 低通滤波器的阻带起始频率
% 下一行的lowpass是用fdatool设计的滤波器保存为matlab code自己修改了一下
[lowpass_b,lowpass_a] = tf(lowpass(lowpass_Fs,lowpass_Fpass,lowpass_Fstop));% 得到滤波器系数
 
s_LPF1=conv(s,lowpass_b);
s_LPF2=conv(s,lowpass_b,"same");
figure(2);
% signal_frequencyspectrum(s_LPF2,fs);
grid on;
xlabel('Frequency/Hz');ylabel('Amplitude/dB');
 
h = fopen('fir_data.txt','w');
for i=1:K
    result= fi(s(i), 1, 24, 0).bin;
    fprintf(h,'%s\n',result);
end
fclose(h);
 
figure
plot(s)

figure
plot(s_LPF1)
 
figure
plot(s_LPF2)