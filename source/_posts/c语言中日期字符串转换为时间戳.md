---
title: c语言中日期字符串转换为时间戳
author: yirufeng
pin: false
toc: true
categories:
  - C/C++
tags:
  - C/C++
  - 时间
date: 2022-09-28 10:44:14
---


## 字符串与时间戳的转换
### 日期字符串转换为时间戳
思路：
1. 将日期字符串转换为时间结构体
2. 将时间结构体转换为对应的时间戳(`time_t`类型，其实是`long`类型的别名)


{% folding cyan open, 日期字符串转换为时间戳 %}
```c++
time_t convertDateToTimestamp(const string &date)
{
    // 首先在后面添加时间
    char dateTimeBuf[64];
    snprintf(dateTimeBuf, sizeof(dateTimeBuf), "%s 00:00:00", date.c_str());
    struct tm dateTM;
    strptime(dateTimeBuf, "%Y-%m-%d %H:%M:%S", &dateTM);
    return mktime(&dateTM);
}
```
{% endfolding %}

### 日期时间字符串转换为时间戳
思路：
1. 将日期字符串转换为时间结构体
2. 将时间结构体转换为对应的时间戳(`time_t`类型，其实是`long`类型的别名)

{% folding green, 日期时间字符串转换为时间戳 %}
```c++
// 日期时间字符串转换为对应的时间戳
time_t convertDatetimeToTimestamp(const string &date_time)
{
    struct tm dtTM;
    strptime(date_time.c_str(), "%Y-%m-%d %H:%M:%S", &dtTM);
    return mktime(&dtTM);
}
```
{% endfolding %}

### 时间戳转换为日期字符串
思路：
1. 将时间戳转换为`struct tm`类型的时间：使用`localtime_r`函数或者`localtime`函数
2. 然后将`struct tm`类型的时间按照给定格式化串格式化为字符串：使用`strftime`函数

{% folding green, 时间戳转换为日期字符串 %}
```c++
// 时间戳转换为日期
void convertTimestampToDate(time_t timestamp, string &date)
{
    // 1. 将时间戳转换为struct tm类型:
    // localtime是不可重入函数，非线程安全，但是localtime_r是可重入函数，线程安全的
    struct tm dateTm;
    localtime_r(&timestamp, &dateTm);
    printf("%d-%d-%d\n", dateTm.tm_year + 1900, dateTm.tm_mon + 1,
           dateTm.tm_mday);
    // 2. 将struct tm类型转换为自定义格式化字符串
    char dateBuf[16];
    strftime(dateBuf, sizeof(dateBuf), "%Y-%m-%d", &dateTm);
    date = dateBuf;
}
```
{% endfolding %}

### 时间戳转换为日期时间字符串
思路：
1. 将时间戳转换为`struct tm`类型的时间：使用`localtime_r`函数或者`localtime`函数
2. 然后将`struct tm`类型的时间按照给定格式化串格式化为字符串：使用`strftime`函数

{% folding green, 时间戳转换为日期时间字符串 %}
```c++
// 时间戳转换为日期时间
void convertTimestampToDatetime(time_t timestamp, string &date_time)
{
    // 1. 将时间戳转换为struct tm类型:
    // localtime是不可重入函数，非线程安全，但是localtime_r是可重入函数，线程安全的
    struct tm dateTimeTm;
    localtime_r(&timestamp, &dateTimeTm);
    // 2. 将struct tm类型转换为自定义格式化字符串
    char dateTimeBuf[32];
    strftime(dateTimeBuf, sizeof(dateTimeBuf), "%Y-%m-%d %H:%M:%S",
             &dateTimeTm);
    date_time = dateTimeBuf;
}
```
{% endfolding %}

<!-- more -->


## 参考文章
1. [【C语言笔记】时间日期函数](https://mp.weixin.qq.com/s/y4Oe0gZ0_rwwW3XcdwJg7w)
2. [【笔记】整理C语言的时间函数](https://mp.weixin.qq.com/s/LsQXRqq7SZqI_y45O_0g3Q)

## 完整代码

```c++
#include <stdio.h>
#include <string>
#include <time.h>
using namespace std;

// 日期字符串转换为对应的时间戳
time_t convertDateToTimestamp(const string &date)
{
    // 首先在后面添加时间
    char dateTimeBuf[64];
    snprintf(dateTimeBuf, sizeof(dateTimeBuf), "%s 00:00:00", date.c_str());
    struct tm dateTM;
    strptime(dateTimeBuf, "%Y-%m-%d %H:%M:%S", &dateTM);
    return mktime(&dateTM);
}

// 日期时间字符串转换为对应的时间戳
time_t convertDatetimeToTimestamp(const string &date_time)
{
    struct tm dtTM;
    strptime(date_time.c_str(), "%Y-%m-%d %H:%M:%S", &dtTM);
    return mktime(&dtTM);
}

// 时间戳转换为日期
void convertTimestampToDate(time_t timestamp, string &date)
{
    // 1. 将时间戳转换为struct tm类型:
    // localtime是不可重入函数，非线程安全，但是localtime_r是可重入函数，线程安全的
    struct tm dateTm;
    localtime_r(&timestamp, &dateTm);
    printf("%d-%d-%d\n", dateTm.tm_year + 1900, dateTm.tm_mon + 1,
           dateTm.tm_mday);
    // 2. 将struct tm类型转换为自定义格式化字符串
    char dateBuf[16];
    strftime(dateBuf, sizeof(dateBuf), "%Y-%m-%d", &dateTm);
    date = dateBuf;
}

// 时间戳转换为日期时间
void convertTimestampToDatetime(time_t timestamp, string &date_time)
{
    // 1. 将时间戳转换为struct tm类型:
    // localtime是不可重入函数，非线程安全，但是localtime_r是可重入函数，线程安全的
    struct tm dateTimeTm;
    localtime_r(&timestamp, &dateTimeTm);
    // 2. 将struct tm类型转换为自定义格式化字符串
    char dateTimeBuf[32];
    strftime(dateTimeBuf, sizeof(dateTimeBuf), "%Y-%m-%d %H:%M:%S",
             &dateTimeTm);
    date_time = dateTimeBuf;
}

int main(int argc, char const *argv[])
{
    printf("%d\n", convertDateToTimestamp("2022-09-23"));
    printf("%d\n", convertDatetimeToTimestamp("2022-09-23 15:23:59"));
    string date;
    string date_time;
    convertTimestampToDate(1663917839, date);
    convertTimestampToDatetime(1663917839, date_time);

    printf("%s\n", date.c_str());
    printf("%s\n", date_time.c_str());
    return 0;
}
```