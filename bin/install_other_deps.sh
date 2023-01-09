#!/usr/bin/env bash

source echoerr

if ! command -v nc; then
  echoerr 'netcat is not installed. installing it now'
  sudo apt install netcat
else
  echoerr 'netcat is already installed'
fi