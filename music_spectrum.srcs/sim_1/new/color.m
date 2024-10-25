close all; clear all;
m=200;n=20;s=0.85;l=0.6;
H=ones(m,n).*0;
S=ones(m,n).*s;
L=ones(m,n).*l;
img= cat(3,H,S,L);
[R,G,B,rgb]=hsl2rgb(img); 
figure;

fp = fopen('color.txt','w');
for i=0:127
    H=ones(m,n).*(i/127*360);
    img= cat(3,H,S,L);
    [R,G,B,rgb_add]=hsl2rgb(img);
    rgb=[rgb rgb_add];
    r=dec2bin(uint8(R(1,1,1)*255),8);
    g=dec2bin(uint8(G(1,1,1)*255),8);
    b=dec2bin(uint8(B(1,1,1)*255),8);
    fprintf(fp,'rom[%.2d] = {16''b%s}; ',i,[r(1:5),g(1:6),b(1:5)]);
    fprintf(fp,'\r\n');
end
imshow(rgb);
fclose(fp);