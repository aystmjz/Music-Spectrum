//////////////////////////////////////////////////////////////////////////////////
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            新芯科技
// All rights reserved
// File name:              FFT_control.v
// Last modified Date:     2024/10/26
// Last Version:           V1.1
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/25
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
#include <stdlib.h>
#include "xgpiops.h"
#include "unistd.h"
#include "ff.h"
#include "xil_cache.h"

#define DDR_BASE_ADDR (XPAR_DDR_MEM_BASEADDR + 0x1800000)
#define IMAGE_WIDTH 800
#define IMAGE_HEIGHT 480
#define BMP_HEAD 0x42

XGpioPs Gpio;
XGpioPs_Config *ConfigPtr;

TCHAR *path = "0:/";
FATFS fatfs;
FRESULT res_sd;

const TCHAR *picpath = "0:/PHOTO";
uint8_t write_ddr(char *pname)
{
    FIL *fbmp;
    uint16_t br;
    uint16_t temp;
    uint8_t res, rval;
    uint8_t *databuf;

    rval = 0;
    fbmp = (FIL *)malloc(sizeof(FIL));            /* 申请内存 */
    databuf = (uint8_t *)malloc(IMAGE_WIDTH * 2); /* 开辟IMAGE_WIDTH*2字节的内存区域 */

    if (databuf == NULL || fbmp == NULL)
    {
        return 0XFF; /* 内存申请失败 */
    }

    res = f_open(fbmp, (const TCHAR *)pname, FA_READ);  /* 打开文件 */
    res = f_read(fbmp, databuf, BMP_HEAD, (UINT *)&br); /* 略过bmp头信息 */
    if (res == 0)
    {
        for (uint16_t y = 1; y <= IMAGE_HEIGHT; y++)
        {
            res = f_read(fbmp, databuf, IMAGE_WIDTH * 2, (UINT *)&br); /* 读出IMAGE_WIDTH*2个字节 */
            if (res != 0)
            {
                rval = 0XFF;
                break;
            }

            for (uint16_t x = 0; x < IMAGE_WIDTH; x++) /* 循环写入内存IMAGE_WIDTH*2个字节 */
            {
                temp = databuf[((x / 4) * 4 + 4 - (x % 4) - 1) * 2 + 1] << 8 | databuf[((x / 4) * 4 + 4 - (x % 4) - 1) * 2]; /* 对应关系 */
                Xil_Out16(DDR_BASE_ADDR + (IMAGE_HEIGHT - y) * IMAGE_WIDTH * 2 + x * 2, temp);
            }
            Xil_DCacheFlushRange(DDR_BASE_ADDR + (IMAGE_HEIGHT - y) * IMAGE_WIDTH * 2, IMAGE_WIDTH * 2);
        }
        f_close(fbmp);
    }
    else
    {
        rval = 0XFF; /* 出现错误 */
    }

    free(databuf);
    free(fbmp);
    return rval;
}

// 获取图片总数
uint8_t Get_Pic_Nums(const TCHAR *path)
{
    uint8_t fileCnt = 0;
    FRESULT res;
    FILINFO finfo;
    TCHAR *fn;
    DIR dir;
    res = f_opendir(&dir, path);
    if (res == FR_OK)
    {
        while (f_readdir(&dir, &finfo) == FR_OK)
        {
            fn = finfo.fname;
            if (!fn[0])
                break;
            fileCnt++;
        }
    }
    f_closedir(&dir);
    return fileCnt;
}

void pic_refresh(const TCHAR *picpath)
{
    uint8_t res;
    DIR picdir;           /* 目录 */
    FILINFO *picfileinfo; /* 文件信息 */
    char *pname;          /* 带路径的文件名 */
    uint16_t totpicnum;   /* 图片文件总数 */
    uint16_t curindex;    /* 图片当前索引 */
    uint16_t temp;
    uint16_t *picoffsettbl; /* 图片索引表 */

    if (f_opendir(&picdir, picpath)) /* 打开图片文件夹 */
    {
        xil_printf("PHOTO文件夹错误!");
        return;
    }

    totpicnum = Get_Pic_Nums(picpath); /* 得到总有效文件数 */

    if (totpicnum == 0) /* 图片文件总数为0 */
    {
        xil_printf("没有图片文件!");
        return;
    }

    picfileinfo = (FILINFO *)malloc(sizeof(FILINFO)); /* 为长文件缓存区分配内存 */
    pname = malloc(2 * FF_MAX_LFN + 1);               /* 为带路径的文件名分配内存 */
    picoffsettbl = malloc(2 * totpicnum);             /* 申请2*totpicnum个字节的内存, 用于存放图片文件索引 */

    if (picfileinfo == NULL || pname == NULL || picoffsettbl == NULL) /* 内存分配出错 */
    {
        xil_printf("内存分配失败!");
        return;
    }

    /* 记录索引 */
    res = f_opendir(&picdir, picpath); /* 打开目录 */
    curindex = 0;                      /* 当前索引为0 */
    while (res == FR_OK)               /* 全部查询一遍 */
    {
        temp = picdir.dptr;                    /* 记录当前offset */
        res = f_readdir(&picdir, picfileinfo); /* 读取目录下的一个文件 */

        if (res != FR_OK || picfileinfo->fname[0] == 0)
        {
            break; /* 错误了/到末尾了,退出 */
        }

        picoffsettbl[curindex] = temp; /* 记录索引 */
        curindex++;
    }

    curindex = 0;                      /* 从0开始显示 */
    res = f_opendir(&picdir, picpath); /* 打开目录 */

    while (res == FR_OK)
    {
        dir_sdi(&picdir, picoffsettbl[curindex]); /* 改变当前目录索引 */
        res = f_readdir(&picdir, picfileinfo);    /* 读取目录下的一个文件 */

        if (res != FR_OK || picfileinfo->fname[0] == 0)
        {
            break; /* 错误了/到末尾了,退出 */
        }
        strcpy((char *)pname, picpath);
        strcat((char *)pname, "/");
        strcat((char *)pname, (const char *)picfileinfo->fname); /* 将文件名接在后面 */
        xil_printf("%d/%d :%s", curindex + 1, totpicnum, picfileinfo->fname);

        if (write_ddr(pname) != 0) /* 写入DDR */
            break;

        uint8_t led_cnt = 0;
        while (XGpioPs_ReadPin(&Gpio, 47) == 1)
        {
            usleep(30000);
            led_cnt++;
            led_cnt %= 10;
            if (led_cnt < 5)
                XGpioPs_WritePin(&Gpio, 7, 0x1);
            else
                XGpioPs_WritePin(&Gpio, 7, 0x0);
        }
        curindex++;
        curindex %= totpicnum;
    }

    free(picfileinfo);
    free(pname);
    free(picoffsettbl);
}

int main(void)
{
    ConfigPtr = XGpioPs_LookupConfig(XPAR_PS7_GPIO_0_DEVICE_ID);
    XGpioPs_CfgInitialize(&Gpio, ConfigPtr, ConfigPtr->BaseAddr);
    XGpioPs_SetDirectionPin(&Gpio, 7, 1);
    XGpioPs_SetOutputEnablePin(&Gpio, 7, 1);
    XGpioPs_SetDirectionPin(&Gpio, 47, 0);
    XGpioPs_SetOutputEnablePin(&Gpio, 47, 0);

    while (1)
    {
        res_sd = f_mount(&fatfs, path, 0);
        if (res_sd == FR_OK)
        {
            xil_printf("SD卡挂载成功!\r\n");
            XGpioPs_WritePin(&Gpio, 7, 0x1);
            pic_refresh(picpath);
        }
        else
        {
            xil_printf("SD卡挂载失败!\r\n");
            XGpioPs_WritePin(&Gpio, 7, 0x0);
        }
        xil_printf("出现错误，正在重试\r\n");
    }

    return 0;
}
