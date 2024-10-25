//////////////////////////////////////////////////////////////////////////////////
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            ��о�Ƽ�
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
    fbmp = (FIL *)malloc(sizeof(FIL));            /* �����ڴ� */
    databuf = (uint8_t *)malloc(IMAGE_WIDTH * 2); /* ����IMAGE_WIDTH*2�ֽڵ��ڴ����� */

    if (databuf == NULL || fbmp == NULL)
    {
        return 0XFF; /* �ڴ�����ʧ�� */
    }

    res = f_open(fbmp, (const TCHAR *)pname, FA_READ);  /* ���ļ� */
    res = f_read(fbmp, databuf, BMP_HEAD, (UINT *)&br); /* �Թ�bmpͷ��Ϣ */
    if (res == 0)
    {
        for (uint16_t y = 1; y <= IMAGE_HEIGHT; y++)
        {
            res = f_read(fbmp, databuf, IMAGE_WIDTH * 2, (UINT *)&br); /* ����IMAGE_WIDTH*2���ֽ� */
            if (res != 0)
            {
                rval = 0XFF;
                break;
            }

            for (uint16_t x = 0; x < IMAGE_WIDTH; x++) /* ѭ��д���ڴ�IMAGE_WIDTH*2���ֽ� */
            {
                temp = databuf[((x / 4) * 4 + 4 - (x % 4) - 1) * 2 + 1] << 8 | databuf[((x / 4) * 4 + 4 - (x % 4) - 1) * 2]; /* ��Ӧ��ϵ */
                Xil_Out16(DDR_BASE_ADDR + (IMAGE_HEIGHT - y) * IMAGE_WIDTH * 2 + x * 2, temp);
            }
            Xil_DCacheFlushRange(DDR_BASE_ADDR + (IMAGE_HEIGHT - y) * IMAGE_WIDTH * 2, IMAGE_WIDTH * 2);
        }
        f_close(fbmp);
    }
    else
    {
        rval = 0XFF; /* ���ִ��� */
    }

    free(databuf);
    free(fbmp);
    return rval;
}

// ��ȡͼƬ����
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
    DIR picdir;           /* Ŀ¼ */
    FILINFO *picfileinfo; /* �ļ���Ϣ */
    char *pname;          /* ��·�����ļ��� */
    uint16_t totpicnum;   /* ͼƬ�ļ����� */
    uint16_t curindex;    /* ͼƬ��ǰ���� */
    uint16_t temp;
    uint16_t *picoffsettbl; /* ͼƬ������ */

    if (f_opendir(&picdir, picpath)) /* ��ͼƬ�ļ��� */
    {
        xil_printf("PHOTO�ļ��д���!");
        return;
    }

    totpicnum = Get_Pic_Nums(picpath); /* �õ�����Ч�ļ��� */

    if (totpicnum == 0) /* ͼƬ�ļ�����Ϊ0 */
    {
        xil_printf("û��ͼƬ�ļ�!");
        return;
    }

    picfileinfo = (FILINFO *)malloc(sizeof(FILINFO)); /* Ϊ���ļ������������ڴ� */
    pname = malloc(2 * FF_MAX_LFN + 1);               /* Ϊ��·�����ļ��������ڴ� */
    picoffsettbl = malloc(2 * totpicnum);             /* ����2*totpicnum���ֽڵ��ڴ�, ���ڴ��ͼƬ�ļ����� */

    if (picfileinfo == NULL || pname == NULL || picoffsettbl == NULL) /* �ڴ������� */
    {
        xil_printf("�ڴ����ʧ��!");
        return;
    }

    /* ��¼���� */
    res = f_opendir(&picdir, picpath); /* ��Ŀ¼ */
    curindex = 0;                      /* ��ǰ����Ϊ0 */
    while (res == FR_OK)               /* ȫ����ѯһ�� */
    {
        temp = picdir.dptr;                    /* ��¼��ǰoffset */
        res = f_readdir(&picdir, picfileinfo); /* ��ȡĿ¼�µ�һ���ļ� */

        if (res != FR_OK || picfileinfo->fname[0] == 0)
        {
            break; /* ������/��ĩβ��,�˳� */
        }

        picoffsettbl[curindex] = temp; /* ��¼���� */
        curindex++;
    }

    curindex = 0;                      /* ��0��ʼ��ʾ */
    res = f_opendir(&picdir, picpath); /* ��Ŀ¼ */

    while (res == FR_OK)
    {
        dir_sdi(&picdir, picoffsettbl[curindex]); /* �ı䵱ǰĿ¼���� */
        res = f_readdir(&picdir, picfileinfo);    /* ��ȡĿ¼�µ�һ���ļ� */

        if (res != FR_OK || picfileinfo->fname[0] == 0)
        {
            break; /* ������/��ĩβ��,�˳� */
        }
        strcpy((char *)pname, picpath);
        strcat((char *)pname, "/");
        strcat((char *)pname, (const char *)picfileinfo->fname); /* ���ļ������ں��� */
        xil_printf("%d/%d :%s", curindex + 1, totpicnum, picfileinfo->fname);

        if (write_ddr(pname) != 0) /* д��DDR */
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
            xil_printf("SD�����سɹ�!\r\n");
            XGpioPs_WritePin(&Gpio, 7, 0x1);
            pic_refresh(picpath);
        }
        else
        {
            xil_printf("SD������ʧ��!\r\n");
            XGpioPs_WritePin(&Gpio, 7, 0x0);
        }
        xil_printf("���ִ�����������\r\n");
    }

    return 0;
}
