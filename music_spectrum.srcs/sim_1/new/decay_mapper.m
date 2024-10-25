close all; clear all;

N = 80;
n = 0:N;
a=1.085;
b=1.07;
c=3.5;
f=round((realpow(a,n)+realpow(n,b))/2+n/c);

fp = fopen('\mapper.txt','w');
for i = 0:N
     fprintf(fp,'rom[%.2d] = {10''d%d}; ',i,round((realpow(a,i)+realpow(i,b))/2+i/c));
     fprintf(fp,'\r\n');
end
fclose(fp);


figure;
plot(n,f);
figure;
plot(n,f/1024*44.1*1000);

hold on;

p1=20;
p2=70;
p3=80;
text(p1,f(p1)+2000,['P(',num2str(p1),',',num2str(round(f(p1)/1024*44.1*1000)),')'])
text(p2-5,f(p2)+8000,['P(',num2str(p2),',',num2str(round(f(p2)/1024*44.1*1000)),')'])
text(p2-5,f(p3)+16000,['P(',num2str(p3),',',num2str(round(f(p3)/1024*44.1*1000)),')'])
xlabel('x');
ylabel('y')


