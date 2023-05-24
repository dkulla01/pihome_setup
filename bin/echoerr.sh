#!/usr/bin/env bash
echoerr() {
  printf -v joined_segments "%s " "$@"
  printf "%s\n" "$joined_segments" >&2
}
