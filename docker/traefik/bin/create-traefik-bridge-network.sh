#!/usr/bin/env bash

docker network create \
--driver bridge \
--subnet 172.22.0.0/24 \
traefik-net
