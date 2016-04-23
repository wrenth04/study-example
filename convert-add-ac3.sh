#!/bin/bash

name="$1"
output="movie/$name"

mkdir movie

ffmpeg -nostdin -y -i "$name" -map 0:1 -c:a ac3 "$name.ac3"
ffmpeg -nostdin -y -i "$name" -i "$name.ac3" -map 0 -map 1:a -c copy "$output"

