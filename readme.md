This repo has a patch to enable chromium to be ran on android automotive, along with scritps to help ease the build process. 
# Android Setup
```
cd ~/
git clone https://github.com/bisonbet/chromium_aaos.git chromium
cd chromium
```
Follow the offical [google chromium guide](https://chromium.googlesource.com/chromium/src/+/main/docs/android_build_instructions.md)  
During the "Setting up the build", run ``` gn args out/Release_arm64``` and copy the contents of [Release_arm64.gn](/Release_arm64.gn).
To build, you could continue to use the offical guide but these instructions going forward will use custom build scripts. It is helpful to still have the chromium guide pulled up while running through this readme. 
# Building
### Dependencies
The following folder structure exists  
```
|$HOME
|  |--chromium
|       pull_latest.sh
|       etc.   
|     |--src  
|  |--Android  
|     |--Sdk  
|        |--build-tools  
|  |--Documents
|     |--KeyStore
|          store.jks
```
Android build tools is needed for the signing of the aab. I used android studio to create my signing key, but I'm sure there is an terminal command to accomplish creating a .jks.  
### Apply automotive path to source
Run ```./pull_latest.sh```. This will:  
1. Fetch the latest chromium code
2. Apply a patch to make the app "AAOS compatible"
3. runhooks  
## Building for target

### Making a release
Run ```./build_release.sh```. This proces will take hours to complete. This will:
1. Setup parameters based on target architecture
2. Find latest version file, and bump the major by 1
3. Run build command to build an app bundle (.aab)
4. Sign the .aab output file (needed to upload to Play Store) - Will ask to enter password  
Output: ```$HOME/chromium/src/out/Release_arm64/apks/MonochromePublic6432.aab```

## Building for emulator
**TODO**  
```./build_apk.sh ```

## Uploading to Play Store
**TODO**  
1. Create dev account 
2. Go to [Google Play Console](https://play.google.com/console)
3. Create a new app
4. Add Automotive OS only form factor
5. Publish app to internal testing
6. Add privacy statement
7. Add testers emails
8. Go to the "Copy link" URL and install the app to your target device