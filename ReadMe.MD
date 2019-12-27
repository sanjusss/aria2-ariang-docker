[![GitHub](https://img.shields.io/github/license/sanjusss/aria2-ariang-docker)](https://github.com/sanjusss/aria2-ariang-docker/blob/master/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/sanjusss/aria2-ariang-docker)](https://hub.docker.com/r/sanjusss/aria2-ariang-docker)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/sanjusss/aria2-ariang-docker)](https://github.com/sanjusss/aria2-ariang-docker/tags)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/sanjusss/aria2-ariang-docker/Docker%20Image%20CI)](https://github.com/sanjusss/aria2-ariang-docker/actions)

# 仓库地址
Docker Hub https://hub.docker.com/r/sanjusss/aria2-ariang-docker  
Github https://github.com/sanjusss/aria2-ariang-docker  

# 简介
本镜像打包了Aria2、AriaNg，支持密码验证，无需手动设置aria2 rpc。支持设置AriaNg为任意端口。可以设置自动更新BT Tracker。自动保存aria2进度。支持基于uid、gid的文件权限设置。  
本镜像支持的平台/CPU架构有：
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/ppc64le
   - linux/s390x

如果还需要文件浏览器或Webdav，可以自行安装FileRun、NextCloud或FileBrowser。如果需要打包Aria2、AriaNg、文件浏览器为一个容器，请查看[https://github.com/wahyd4/aria2-ariang-docker](https://github.com/wahyd4/aria2-ariang-docker)。 

# 快速启动
```shell
docker run -d --name aria2 -p 80:80 -v ./data:/data sanjusss/aria2-ariang-docker
```
访问服务器IP即可进入AriaNg界面，默认用户密码均为admin。

# 参数
可以直接参考[Dockerfile](https://github.com/sanjusss/aria2-ariang-docker/blob/master/Dockerfile)。

## 环境变量
| 环境变量名称 | 注释 |
| :---- | :----- |
| HTTP_PORT | 容器内部使用的AriaNg端口，默认为80，一般不需要修改。 |
| EXTERNAL_PORT | 最终浏览器访问AriaNg使用的端口，例如通过https://wtf.com访问AriaNg，应设置EXTERNAL_PORT值为443。默认值为80。 |
| USER_NAME | 用户名，默认值为admin。 |
| PASSWORD | 密码，默认值为admin。 |
| PUID | 下载、生成文件使用的linux uid，如果想使用root请设置为0，默认值为1000。 |
| PGID | 下载、生成文件使用的linux gid，如果想使用root请设置为0，默认值为1000。 |
| TRACKER_URL | 更新BT Tracker的网址，一般不需要修改。 |
| ENABLE_UPDATE_TRACKER | 是否定时自动更新BT Tracker的网址，默认值为true。 |

## 挂载路径
| 容器路径 | 注释 |
| :---- | :----- |
| /data | aria2的默认下载路径，必须挂载。 |
| /conf | aria2的默认设置路径，如果需要保存进度记录，请挂载此项。 |

# Docker-Compose示例
docker-compose.yml文件
```yml
version: '3'
services:
    aria2:
        image: sanjusss/aria2-ariang-docker
        container_name: aria2
        restart: always
        environment:
            PUID: 1000
            PGID: 1000
            EXTERNAL_PORT: 80
            USER_NAME: user
            PASSWORD: 123456
        volumes:
            - ./conf:/conf
            - /data:/data
            - /etc/localtime:/etc/localtime:ro
        ports:
            - 80:80
```

# 示例
假设我需要在5003端口开启服务，下载路径为/home/data，aria2设置保存到/home/aria2,登录用户为user，密码为123456，UID/GID为1000。

## 命令行启动
```shell
docker run -d --name aria2 \
	-p 5003:80 \
    -v /home/data:/data \
    -v /home/aria2:/conf \
    -e PUID=1000 \
    -e PGID=1000 \
    -e EXTERNAL_PORT=5003 \
    -e USER_NAME=user \
    -e PASSWORD=123456 \
    sanjusss/aria2-ariang-docker
```

## Docker-Compose启动
docker-compose.yml文件
```yml
version: '3'
services:
    aria2:
        image: sanjusss/aria2-ariang-docker
        container_name: aria2
        environment:
            PUID: 1000
            PGID: 1000
            EXTERNAL_PORT: 5003
            USER_NAME: user
            PASSWORD: 123456
        volumes:
            - /home/aria2:/conf
            - /home/data:/data
        ports:
            - 5003:80
```

# 常见问题
## 重启/重建容器后，进入AriaNg界面，无法自动连接到服务器。
打开AriaNg界面，按`Ctrl + F5`刷新，然后点击`AriaNg 设置`——`全局`——`重置设置`（这个按钮很小，在下面），再按`F5`刷新，即可解决。  
这个问题可以通过修改AriaNg解决，希望有熟悉前端同学帮忙。