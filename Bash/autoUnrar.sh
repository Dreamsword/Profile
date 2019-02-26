#!/bin/bash
rarDir=(/path/to/diroctory/)

# Check if there is an unrar process aleady running.
if ps -ef | grep -v grep | grep -v unrarall | grep unrar ; then
  exit 0
else
  find "$rarDir" -maxdepth 1 -mindepth 1 -type d | while read line; do
    # Change the top dir name so that other scripts / app interfere with extraction.
    mv "$line" "$line"_unpacking
    unrar e -r -o- "$line"_unpacking/*.rar "$line"_unpacking
    mv "$line"_unpacking "$line"
  done
fi