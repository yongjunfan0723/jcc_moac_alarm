#!/bin/bash

cross-env Contract=$1 Node=$2 Mainnet=$3 nuxt-ts generate

# test node (打包测试版)
# npm run generate 0xc87f0b41e26da5919837427e46eb8b2e683380e7 https://mtnode1.jccdex.cn false

# production node (打包正式版)
# npm run generate 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 https://chain3.mytokenpocket.vip true

# 上传服务器
rsync -avz -e 'ssh -p 6422' dist/ front@58.243.201.56:~/xubo/jcc-oracle-front/dist

# 同步服务器脚本 （ https://oracle.jccdex.cn ）
# curl -X POST -d 'job=jcc-oracle-front' -d 'token=11ee4eebfbbd434e4871844a4b9e0dbffa'  http://jenkins.jccdex.cn:8090/buildByToken/build