close all; clear all;

Fs=1000;                         %采样率
%t=0:1/Fs:63/Fs;             %数据时长：64个采样周期
N = 1024;
n = 1:N;
t = n/Fs;
% 生成测试信号
f1 = 100;
f2 = 300;
s1 = cos(2*pi*f1*t);    
s2 = cos(2*pi*f2*t);
signalN = s1 + s2 ;
data_before_fft = 800*signalN;  %系数放大100倍

num=24;

fp = fopen('\data_before_fft.txt','w');
for i = 1:N
  if(data_before_fft(i)>=0)
     temp= dec2bin(data_before_fft(i) , num);
 else
     temp= dec2bin(data_before_fft(i)+2^num+1, num);
 end
   for j=1:num
      fprintf(fp,'%s',temp(j));
  end
   fprintf(fp,'\r\n');
end
fclose(fp);


plot(n,data_before_fft);

data_before_fft=[data_before_fft zeros(1,1024-128)];

figure;
y = fft(data_before_fft,N);
y = abs(y);
f = n*Fs/N;
plot(f,y);

figure;
y = fft(data_before_fft,N);
y = abs(y);
f = n;
plot(f,y);


figure;
y = fft(data_before_fft,N);
y = abs(y);
f = n;
plot(f,y/1024);

