---
title: Go对Influxdb进行统计
author: yirufeng
pin: false
toc: true
mathjax: false
sidebar:
  - blogger
  - webinfo
  - tagcloud
  - category
categories:
  - Influxdb
tags:
  - Influxdb
  - Go
date: 2023-01-31 22:38:49
summary:
---

> 需求背景：部门有大量的数据使用Influxdb进行存储，在这个过程中，我们往往需要对存储的数据做一些指标的统计，比如数据占用的磁盘空间，存储了多少条记录等等，但是部分操作需要大量的Influxdb Sql太费时，于是写了一个简单的程序进行统计



## 环境要求
1. Influxdb 1.8 or earlier
2. Go

<!-- more -->

## 指标统计

### 统计Influxdb指定数据库中有多少条数据记录

1. 使用Influxdb提供的Go API, 原理其实就是使用`select count(*) from 表名`统计每个表中数据的数量
{% folding green, 代码 %}

```go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/sirupsen/logrus"

	client "github.com/influxdata/influxdb1-client/v2"
)

var (
	influxdbIp   string
	influxdbPort int
	influxdbName string
)

// connInflux
// @Description: 连接influxdb
// @return client.Client:
func connInflux() client.Client {
	cli, err := client.NewHTTPClient(client.HTTPConfig{
		Addr: fmt.Sprintf("http://%s:%d", influxdbIp, influxdbPort),
		//Username: "admin",
		//Password: "",
	})
	if err != nil {
		log.Fatal(err)
	}
	return cli
}

// queryDB
// @Description: 从influxdb中执行查询
// @param cli:
// @param cmd:
// @return res:
// @return err:
func queryDB(cli client.Client, cmd string, dbName string) (res []client.Result, err error) {
	q := client.Query{
		Command:  cmd,
		Database: dbName,
	}
	if response, err := cli.Query(q); err == nil {
		if response.Error() != nil {
			return res, response.Error()
		}
		res = response.Results
	} else {
		return res, err
	}
	return res, nil
}

// GetDbDataCount
// @Description: 获取指定数据库所有表的记录总数
// @return int: 记录总数
// @return error:
func GetDbDataCount(conn client.Client) (int64, error) {
	// 获取数据库里面有哪些数据表
	var err error
	measurementNameList, err := GetMeasurementsCount(conn)

	var count int64
	if err != nil {
		logrus.Error(err.Error())
		return 0, err
	}

	for i := 0; i < len(measurementNameList); i++ {
		// 查询所有的表
		influxdbSQL := fmt.Sprintf("SELECT COUNT(*) FROM %s", measurementNameList[i])
		ret, err := queryDB(conn, influxdbSQL, influxdbName)
		if err != nil {
			log.Fatal(err)
		}

		if len(ret[0].Series) == 0 {
			return 0, nil
		}

		// json.Number 转换为 int64
		tempNum, err := ret[0].Series[0].Values[0][1].(json.Number).Int64()
		if err != nil {
			log.Fatal(err)
		}
		count += tempNum
	}

	return count, nil
}

func GetMeasurementsCount(conn client.Client) ([]string, error) {
	influxdbQuerySql := fmt.Sprintf("show measurements")
	ret, err := queryDB(conn, influxdbQuerySql, influxdbName)

	if err != nil {
		logrus.Error(err.Error())
		return []string{}, err
	}

	if len(ret[0].Series) == 0 {
		return []string{}, nil
	}

	var measurementNameList []string
	for i := 0; i < len(ret[0].Series[0].Values); i++ {
		measurementNameList = append(measurementNameList, ret[0].Series[0].Values[i][0].(string))
	}

	return measurementNameList, nil
}

// initConfig
// @Description: 初始化配置
func initConfig() {
	logrus.Info("start to get config from command args!!!")
	// 获取Influxdb的IP地址
	flag.StringVar(&influxdbIp, "h", "", "Influxdb的IP地址")
	// 获取Influxdb要操作数据库的名字
	flag.StringVar(&influxdbName, "n", "", "Influxdb数据库名字")
	// 获取Influxdb端口
	flag.IntVar(&influxdbPort, "p", 8086, "Influxdb的端口, 默认8086")
	// 解析配置
	flag.Parse()
	logrus.Info("succeed to get config from command args!!!")

	if influxdbIp == "" || influxdbName == "" {
		logrus.Fatal("argument not given, please specify influxdbIp or influxdbName")
	}
}

func init() {
	initConfig()
}

func main() {
	// 1. 连接influxdb
	conn := connInflux()
	// 2. 查询所有表
	count, err := GetDbDataCount(conn)

	if err != nil {
		log.Fatal(err)
	}

	logrus.Infof("statistical database is completed, %d records are obtained in total", count)
}
```
{% endfolding %}

### 统计数据库占用磁盘空间
1. 进入influxdb的数据存储目录data，然后执行命令`du --max-depth=1 -lh ./`统计当前各个目录所占磁盘空间，其中当前的各个目录名表示的就是Influxdb的数据库名

### 注意事项
1. 如果数据表中数据量很大，使用`select count(*) from 表名`统计的时候会造成CPU与磁盘高负载，极有可能会对生产业务机器造成较大影响，在这段时间中，写入数据将会产生很大时延

