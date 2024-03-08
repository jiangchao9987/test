#!/usr/bin/env bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

set -e

#read -p "Enter the URL from email: " PRESIGNED_URL
PRESIGNED_URL="https://download.llamameta.net/*?Policy=eyJTdGF0ZW1lbnQiOlt7InVuaXF1ZV9oYXNoIjoic2VwbmZpcWk3ZTdpOXQydmYxdXE5d2I2IiwiUmVzb3VyY2UiOiJodHRwczpcL1wvZG93bmxvYWQubGxhbWFtZXRhLm5ldFwvKiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTcwOTcyMDkxOX19fV19&Signature=f5rlrfrtTek2f1N42VfY0oD8VKqpEaK1kog2zCsrZ%7EioDvpo6dJ5M9wQaw0MzkMtK39B3BPYKk98JCtBbxD3d0KHMwBeqQ57b41Is6VRpjJfK2wyKbLMuiRz2KE4WMVEk1MCLutnpTHxF1nWOQUcLU8NoDiHcyGyIRmFsYhAXq1gYebUMdIGuVhIS1Kx3NqGV6TJkJSmk%7ERDfU2x3lJR9jU398ucJY2Xlkz6dVDj12dnuTnWOboPt73AAPfORaVkKkO8TjEYnEm7qJx2utdAoanvK8RKLgX6Rahy3tVn1ug2nXJTDeh-a3unybl1UyT5cQj2i0TNfo9JVRBJWcpW2Q__&Key-Pair-Id=K15QRJLYKIFSLZ&Download-Request-ID=1190518492130342"
echo ""
#read -p "Enter the list of models to download without spaces (7B,13B,70B,7B-chat,13B-chat,70B-chat), or press Enter for all: " MODEL_SIZE
MODEL_SIZE="7B-chat"
TARGET_FOLDER="."             # where all files should end up
mkdir -p ${TARGET_FOLDER}

if [[ $MODEL_SIZE == "" ]]; then
    MODEL_SIZE="7B,13B,70B,7B-chat,13B-chat,70B-chat"
fi

echo "Downloading LICENSE and Acceptable Usage Policy"
wget --continue ${PRESIGNED_URL/'*'/"LICENSE"} -O ${TARGET_FOLDER}"/LICENSE"
wget --continue ${PRESIGNED_URL/'*'/"USE_POLICY.md"} -O ${TARGET_FOLDER}"/USE_POLICY.md"

echo "Downloading tokenizer"
wget --continue ${PRESIGNED_URL/'*'/"tokenizer.model"} -O ${TARGET_FOLDER}"/tokenizer.model"
wget --continue ${PRESIGNED_URL/'*'/"tokenizer_checklist.chk"} -O ${TARGET_FOLDER}"/tokenizer_checklist.chk"
CPU_ARCH=$(uname -m)
  if [ "$CPU_ARCH" = "arm64" ]; then
    (cd ${TARGET_FOLDER} && md5 tokenizer_checklist.chk)
  else
    (cd ${TARGET_FOLDER} && md5sum -c tokenizer_checklist.chk)
  fi

for m in ${MODEL_SIZE//,/ }
do
    if [[ $m == "7B" ]]; then
        SHARD=0
        MODEL_PATH="llama-2-7b"
    elif [[ $m == "7B-chat" ]]; then
        SHARD=0
        MODEL_PATH="llama-2-7b-chat"
    elif [[ $m == "13B" ]]; then
        SHARD=1
        MODEL_PATH="llama-2-13b"
    elif [[ $m == "13B-chat" ]]; then
        SHARD=1
        MODEL_PATH="llama-2-13b-chat"
    elif [[ $m == "70B" ]]; then
        SHARD=7
        MODEL_PATH="llama-2-70b"
    elif [[ $m == "70B-chat" ]]; then
        SHARD=7
        MODEL_PATH="llama-2-70b-chat"
    fi

    echo "Downloading ${MODEL_PATH}"
    mkdir -p ${TARGET_FOLDER}"/${MODEL_PATH}"

    for s in $(seq -f "0%g" 0 ${SHARD})
    do
        wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/consolidated.${s}.pth"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/consolidated.${s}.pth"
    done

    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/params.json"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/params.json"
    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/checklist.chk"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/checklist.chk"
    echo "Checking checksums"
    if [ "$CPU_ARCH" = "arm64" ]; then
      (cd ${TARGET_FOLDER}"/${MODEL_PATH}" && md5 checklist.chk)
    else
      (cd ${TARGET_FOLDER}"/${MODEL_PATH}" && md5sum -c checklist.chk)
    fi
done