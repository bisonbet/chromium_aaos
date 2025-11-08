#!/bin/bash
cd src
git fetch
git reset --hard
git pull
gclient sync
cp ~/chromium/automotive_enhanced.patch .
git apply automotive_enhanced.patch
rm automotive_enhanced.patch
# Shouldn't have to run "gn args out/Release" 
gclient runhooks
