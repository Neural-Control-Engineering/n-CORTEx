#!/bin/bash

camFS=$1
localPath=$2
ffmpeg -f image2 -r $camFS -i $localPath/%10d.png $localPath.mp4
