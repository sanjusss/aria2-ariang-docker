FROM nginx:1.17-alpine

ENV HTTP_PORT=80
ENV USER_NAME=admin
ENV PASSWORD=admin
ENV PUID=1000
ENV PGID=1000

VOLUME /data
VOLUME /conf

WORKDIR /app
ADD run.sh run.sh
RUN chmod +x run.sh
ADD nginx.conf /etc/nginx/conf.d
ADD conf /app/conf
CMD /app/run.sh
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk add --no-cache \
    aria2 \
    wget \
    apache2-utils \
    sudo

RUN ariang_version=1.1.4 \
    && rm -rf /usr/share/nginx/html/* \
    && wget -N --no-check-certificate https://github.com/mayswind/AriaNg/releases/download/${ariang_version}/AriaNg-${ariang_version}.zip \
    && unzip AriaNg-${ariang_version}.zip -d /usr/share/nginx/html \
    && rm -rf AriaNg-${ariang_version}.zip

RUN apk del \
    wget