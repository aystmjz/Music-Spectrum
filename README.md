纯FPGA实现的音乐频谱和波形显示

支持SD卡加载背景图片,可以通过按键自动切换,支持800*480bmp格式图片

ADC采样率24bit 48KHZ,1024点FFT,频谱幅度开根号显示,波形经FIR滤波后触发显示，固定零点稳定在屏幕中心

演示视频：https://www.bilibili.com/video/BV1FDfbYBEGQ

结构框图:

![结构框图](https://github.com/user-attachments/assets/da4a05fc-6d78-474e-b642-b317d63c1956)

频谱显示对应关系：

![image](https://github.com/user-attachments/assets/d8bfcc31-df81-4100-a646-03790ca1163b)

FIR滤波参数：
Fpass:1000 Fstop:2000

![image](https://github.com/user-attachments/assets/481dcd4c-a860-4a19-aa8d-28d099b194ac)

彩虹律动颜色数据:
S=0.85;L=0.6;H=0~360,128级

![image](https://github.com/user-attachments/assets/5539846d-315b-44b6-8a4f-5fbadda27d49)

图像混合模式为强光

![image](https://github.com/user-attachments/assets/d62969b7-7889-4bce-9f69-6df4809f4a60)

显示效果：
![1](https://github.com/user-attachments/assets/d9ffecb5-10fd-4a41-bfb3-76ac68e4100e)
![2](https://github.com/user-attachments/assets/10ac0451-b4bd-4cf1-8212-0e55055b6d63)
![3](https://github.com/user-attachments/assets/40e0fe03-bfd5-4d2a-b685-7de75bd23ee6)
![4](https://github.com/user-attachments/assets/7b7ab2ce-66d9-42c9-babf-22da2685dae5)
