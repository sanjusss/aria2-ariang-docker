#!/bin/sh

if [[ `curl -I -m 10 -o /dev/null -s -w %{http_code} localhost:6800` -ne "000" ]] && \
    [[ `curl -I -m 10 -o /dev/null -s -w %{http_code} localhost:${HTTP_PORT}` -ne "000" ]]
then
    exit 0
else
    exit 1
fi