---
title: 编程使用Github提供的webhook
author: yirufeng
pin: false
toc: true
mathjax: false
categories:
- Github
tags:
- Tool
- Github
date: 2023-02-06 22:22:11
summary: 
---

## 准备环境

1. 云服务器1台
2. 服务器需要安装python3以上的环境，默认服务器都会安装
3. 服务器中需要安装flask：`pip3 install flask`进行安装即可

## 具体流程步骤

1. 仓库中设置webhook
    - payload url填写需要请求服务器的url，这里我们在服务器中部署了一个简单的flask程序，地址是 服务器的ip:flask监听端口
    - 配置Content Type为application/json
    - 配置secret，找个在线生成密码的网站，生成64位密码保存填写进入，并在服务器中通过在`~/.bash_profile`文件最后写入`export SECRET_TOKEN=生成的64位密码`将其添加到环境变量中
    - 选择通知类型为：`Just the push event`
    - 勾选active
2. 根据仓库webhook中设置的secret，需要导入到服务器的环境变量中，
3. 服务器中编写如下的python代码并后台运行，记得设置的端口一定要在防火墙中进行放行

<!-- more -->

```python
import hashlib
import hmac
import os
from flask import Flask, request

app = Flask(__name__)

def validate_signature(req):
    # 获取系统环境变量中设置的webhook secret
    github_webhook_secret = os.getenv('SECRET_TOKEN')
    print("github_webhook_secret: ", github_webhook_secret)
    received_sign = req.headers.get('X-Hub-Signature-256').split('sha256=')[-1].strip()
    secret = github_webhook_secret.encode()
    expected_sign = hmac.HMAC(key=secret, msg=req.data, digestmod=hashlib.sha256).hexdigest()
    return hmac.compare_digest(received_sign, expected_sign)

@app.route("/acceptWebHook", methods=['POST'])
def on_push():
    # 检查签证是否有误
    if validate_signature(request):
        # TODO: 这里要执行自动化部署的脚本
        print("运行自动化脚本，进行自动化部署")
        return "运行自动化脚本，进行自动化部署", 200
    else:
        return "token认证无效", 401

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8900)
```

4. 然后在github中手动修改仓库，发现服务器中打印了 `运行自动化脚本，进行自动化部署` 内容，

## 进阶
> 如果想要使用Go代码来进行Github的webhook推送，请[参考](https://github.com/sivanWu0222/GithubWebhookGo)

## 参考文章
1. [python使用webhook实现自动部署](https://jiuaidu.com/jianzhan/873889/)
2. [GitHub官方文档关于WebHook各个字段的说明](https://docs.github.com/zh/webhooks-and-events/webhooks/webhook-events-and-payloads)