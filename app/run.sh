#!/bin/sh

# 创建密码
htpasswd -bc /etc/nginx/passwd ${USER_NAME} ${PASSWORD}

# 修改端口号，考虑到重启容器的情况。
if [ -f oldHttpPort.txt ]
then
    OLD_HTTP_PORT=`cat oldHttpPort.txt`
else
    OLD_HTTP_PORT=80
fi
sed -i 's/'"${OLD_HTTP_PORT}"'/'"${HTTP_PORT}"'/g' /etc/nginx/conf.d/default.conf
echo ${HTTP_PORT} > oldHttpPort.txt

if [ -f oldExternalPort.txt ]
then
    OLD_EXTERNAL_PORT=`cat oldExternalPort.txt`
else
    OLD_EXTERNAL_PORT=6800
fi
sed -i 's/'"${OLD_EXTERNAL_PORT}"'/'"${EXTERNAL_PORT}"'/g' /usr/share/nginx/html/js/aria-ng*.js
echo ${EXTERNAL_PORT} > oldExternalPort.txt

# 初始化aria2配置
if [ ! -f /conf/aria2.session ] 
then
    touch /conf/aria2.session
fi

if [ ! -f /conf/aria2.conf ] 
then
    cp /app/conf/aria2.conf /conf/aria2.conf
fi

if [ ${ENABLE_AUTO_RANDOM_ARIA} == "true" ] 
then
    # 随机化jsonrcp路径
    if [ -f oldRpcPath.txt ]
    then
        OLD_RPC_PATH=`cat oldRpcPath.txt`
    else
        OLD_RPC_PATH="jsonrpc"
    fi
    RPC_PATH=`cat /proc/sys/kernel/random/uuid`
    sed -i 's/location \/'"${OLD_RPC_PATH}"'/location \/'"${RPC_PATH}"'/g' /etc/nginx/conf.d/default.conf
    sed -i 's/\"'"${OLD_RPC_PATH}"'\"/\"'"${RPC_PATH}"'\"/g' /usr/share/nginx/html/js/aria-ng*.js
    echo ${RPC_PATH} > oldRpcPath.txt

    # 随机化aria2密钥
    OLD_ARIA2_TOKEN=`grep "^rpc-secret=" /conf/aria2.conf`
    ARIA2_TOKEN=`cat /proc/sys/kernel/random/uuid`
    if [ -z "${OLD_ARIA2_TOKEN}" ]
    then
        sed -i '$a rpc-secret='"${ARIA2_TOKEN}" /conf/aria2.conf
    else
        sed -i 's/'"${OLD_ARIA2_TOKEN}"'/rpc-secret='"${ARIA2_TOKEN}"'/g' /conf/aria2.conf
    fi
    BASE64_ARIA2_TOKEN=`echo -n ${ARIA2_TOKEN} | base64`
    sed -i 's/secret:\"[^\"]*\",/secret:\"'"${BASE64_ARIA2_TOKEN}"'\",/g' /usr/share/nginx/html/js/aria-ng*.js

    # 修改aria-ng*.js路径，强制重新加载文件。
    OLD_ARIA_NG_JS=`ls /usr/share/nginx/html/js/aria-ng*.js`
    OLD_ARIA_NG_JS_FILE=${OLD_ARIA_NG_JS##*/}
    ARIA_NG_JS="/usr/share/nginx/html/js/aria-ng"`cat /proc/sys/kernel/random/uuid`".js"
    ARIA_NG_JS_FILE=${ARIA_NG_JS##*/}
    mv "${OLD_ARIA_NG_JS}" "${ARIA_NG_JS}"
    sed -i 's/'"${OLD_ARIA_NG_JS_FILE}"'/'"${ARIA_NG_JS_FILE}"'/g' /usr/share/nginx/html/*.*

    # 随机化cookie
    if [ -f oldCookie.txt ]
    then
        OLD_COOKIE=`cat oldCookie.txt`
    else
        OLD_COOKIE="webcookiemask"
    fi
    COOKIE=`cat /proc/sys/kernel/random/uuid`
    sed -i 's/'"${OLD_COOKIE}"'/'"${COOKIE}"'/g' /etc/nginx/conf.d/default.conf
    echo ${COOKIE} > oldCookie.txt
else
    # 设置ARIA2密钥
    OLD_ARIA2_TOKEN=`grep -Eo "^rpc-secret=.*" /conf/aria2.conf | cut -d '=' -f 2`
    if [[ -z "${OLD_ARIA2_TOKEN}" || "${OLD_ARIA2_TOKEN}" = "token123456" ]]
    then
        ARIA2_TOKEN=`cat /proc/sys/kernel/random/uuid`
        if [[ -z "${OLD_ARIA2_TOKEN}" ]]
        then
            sed -i '$a rpc-secret='"${ARIA2_TOKEN}" /conf/aria2.conf
        else
            sed -i 's/rpc-secret=token123456/rpc-secret='"${ARIA2_TOKEN}"'/g' /conf/aria2.conf
        fi
    else
        ARIA2_TOKEN=${OLD_ARIA2_TOKEN}
    fi
    
    BASE64_ARIA2_TOKEN=`echo -n ${ARIA2_TOKEN} | base64`
    sed -i 's/secret:\"[^\"]*\",/secret:\"'"${BASE64_ARIA2_TOKEN}"'\",/g' /usr/share/nginx/html/js/aria-ng*.js
fi

# 修改AriaNg，每次启动时都重新设置页面。
sed -i 's/body class/body onload="localStorage.clear();" class/g' /usr/share/nginx/html/index.html

# 设置文件权限
chown -R ${PUID}:${PGID} /conf
chown -R ${PUID}:${PGID} /data
touch /var/log/aria2.log
chmod 755 /var/log/aria2.log
chown ${PUID}:${PGID} /var/log/aria2.log

# 设置aria2运行用户
if [ ${PUID} -eq "0" ]
then
    USER=root
else
    USER=aria2
    addgroup --gid "$PGID" "$USER"
    adduser \
        --disabled-password \
        --ingroup "$USER" \
        --no-create-home \
        --uid "$PUID" \
        "$USER"
fi

# 启动nginx
nginx

# 启动cron，自动更新tracker
if [ ${ENABLE_UPDATE_TRACKER} == "true" ] 
then
    crond
fi

# 启动aria2
sudo -u "$USER" /usr/bin/aria2c --conf-path=/conf/aria2.conf
