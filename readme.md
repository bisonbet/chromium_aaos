# Chromium AAOS Compile Tutorial

This is a comprehensive guide on compiling Chromium for any Android Automotive vehicle, but has been tested on the Chevy Equinox EV 2024. This process allows you to install the app using the Internal Tester Function on the Google Play Console.

## 1. Prerequisites and Resources

### Requirements

- **Operating System:** A desktop or laptop running Linux; **Ubuntu recommended**.
- **Hardware:** A powerful multi-core CPU, as the compilation process can take from 18 hours to several days.
  - Minimum of **24GB of RAM** is recommended.
  - Minimum of **200GB of hard drive space** is recommended.
  - SSD/Flash storage is required to complete this before 2087
- **Account:** A **Google Play Console** account to upload the build for Internal Testing. Sign up by [clicking here](https://play.google.com/console).

### Resources

- [Chromium AAOS GitHub Repository](https://github.com/bisonbet/chromium_aaos)
- [Official Chromium Android Build Instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/android_build_instructions.md)

## 2. Setting Up Directories & Paths

### Directory Structure

You will need the Chromium Source Code, Android SDK with build-tools, and a KeyStore file. This is the required directory structure under your `$CHROMIUMBUILD` directory:

```
$CHROMIUMBUILD
|--chromium/
|  |--depot_tools/
|  |--src/ (Chromium source code)
|--chromium_aaos/ (this repository with scripts and patch)
|  |--automotive.patch
|  |--pull_latest.sh
|  |--build_release.sh
|  |--Release_arm64.gn
|  |--Release_X64.gn
|  |--PGO_PROFILES_GUIDE.md
|--Android/
|  |--Sdk/
|     |--build-tools/
|--Documents/
   |--KeyStore/
      |--store.jks
```

### Update Environment Variables

Go into the `~/.bashrc` file and add the following lines at the bottom:

```bash
export CHROMIUMBUILD=/your/base/directory/for/build
export ANDROID_SDK_ROOT=$CHROMIUMBUILD/Android/Sdk
export PATH=$PATH:$CHROMIUMBUILD/Android/Sdk/build-tools/35.0.0:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$CHROMIUMBUILD/chromium/depot_tools
```

### Activate Variables

After adding the lines to `~/.bashrc`, run the following to have the new variables take effect:

```bash
source ~/.bashrc
```

## 3. Downloading Chromium Source Code

### Install Git

Open your Terminal and run:

```bash
sudo apt install git
```

### Clone the Depot Tools

Clone the Chromium `depot_tools` repository:

```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

**Note:** You must place the `depot_tools` folder inside a folder named `chromium` in your `$CHROMIUMBUILD` directory for the build script to work.

### Download Source Code

Run the following commands in your Terminal:

```bash
cd $CHROMIUMBUILD/chromium
fetch --nohooks android
```

**Note:** This download will take a significant amount of time and requires a stable internet connection.

### Install Build Dependencies

Navigate to the source code directory and install the dependencies:

```bash
cd $CHROMIUMBUILD/chromium/src
build/install-build-deps.sh
```

### Run Gclient Hooks

Download the Chromium-specific hooks:

```bash
gclient runhooks
```

## 4. Installing Android SDK Command Line Tools

### Download Command Line Tools

Download the latest commandlinetools zip file:

```bash
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O $CHROMIUMBUILD/Android/commandlinetools.zip
```

### Extract and Structure

Extract the contents into `$CHROMIUMBUILD/Android/Sdk/cmdline-tools/latest`

### Install Java 17

The SDK Manager requires Java 17:

```bash
sudo apt update && sudo apt install openjdk-17-jdk -y
```

### Install Build Tools

Use the `sdkmanager` to install the required `platform-tools` and `build-tools;35.0.0`:

```bash
sdkmanager --install "platform-tools" "build-tools;35.0.0"
```

**Ensure you accept the agreement when prompted!**

## 5. Creating a Keystore File

### Create Directory

Create the directory the build script will use for signing:

```bash
mkdir -p $CHROMIUMBUILD/Documents/KeyStore
```

### Generate Keystore

Navigate to the folder and generate the keystore file:

```bash
cd $CHROMIUMBUILD/Documents/KeyStore
keytool -genkeypair -v -keystore store.jks -alias chromium-key -keyalg RSA -keysize 2048 -validity 3650
```

**Ensure you remember the password and information you enter, as you will need it later.**

## 6. Applying the Chromium AAOS Patch and Configuration

### Clone the Patch Repository

Clone the GitHub repository containing the patch and build scripts into `$CHROMIUMBUILD`:

```bash
git clone https://github.com/bisonbet/chromium_aaos.git $CHROMIUMBUILD/chromium_aaos
```

**Important**: This repository includes the AAOS patch with critical fixes:
- Storage permissions (fixes crash-after-login issue)
- Multi-user support for AAOS
- Direct boot awareness
- Background service permissions
- Profile-Guided Optimization (PGO) profiles enabled

**Note on PGO Profiles**: The patch enables PGO profiles for 5-15% performance improvement. This adds ~1.2GB to initial download and ~3GB disk space. See [PGO_PROFILES_GUIDE.md](PGO_PROFILES_GUIDE.md) for details on impact and how to disable if needed.

### Edit Release_arm64.gn

Open the `$CHROMIUMBUILD/chromium_aaos/Release_arm64.gn` file and replace the string **CHANGEME** with a unique identifier (e.g., your username, or some other string that is unique to you). This is critical for preventing issues when uploading to the Google Play Console.

### Run pull_latest.sh

Navigate to the chromium directory and run the update script to fetch the latest Chromium source and apply the AAOS patch:

```bash
cd $CHROMIUMBUILD/chromium
$CHROMIUMBUILD/chromium_aaos/pull_latest.sh
```

The script will automatically:
1. Update Chromium source to the latest version
2. Find and apply the AAOS patch from `$CHROMIUMBUILD/chromium_aaos/automotive.patch`
3. Run gclient sync and hooks

If you need to use a different patch file, you can specify it as an argument:

```bash
$CHROMIUMBUILD/chromium_aaos/pull_latest.sh /path/to/custom.patch
```

### Generate GN Arguments and Configure Build

Run the following command in Terminal. When the vi editor pops up, you can exit it immediately, as you will edit the file next:

```bash
cd $CHROMIUMBUILD/chromium/src
gn args out/Release_arm64
```

### Edit args.gn

Navigate to the newly created directory `$CHROMIUMBUILD/chromium/src/out/Release_arm64` and open the `args.gn` file with a text editor. Copy the contents of the `$CHROMIUMBUILD/chromium_aaos/Release_arm64.gn` file (with your CHANGEME edits) and paste it into the `args.gn` file.

### Configure build_release.sh (Optional)

If your Chromium source is not located at the default path, open the `$CHROMIUMBUILD/chromium_aaos/build_release.sh` file and update the `DEFAULT_SRC` variable to point to your Chromium source directory, or pass the path as an argument when running the script.

## 7. Compiling Chromium

This is the most time-consuming step.

### Run the Build Script

Run the build script from the chromium_aaos directory:

```bash
cd $CHROMIUMBUILD/chromium_aaos
./build_release.sh
```

By default, the script uses `$CHROMIUMBUILD/chromium/src` as the source directory. If your Chromium source is in a different location, you can pass it as an argument:

```bash
./build_release.sh /path/to/chromium/src
```

### Enter Keystore Password

When prompted, enter the password you created for your KeyStore file in Step 5.

### Output

Upon successful completion, the Android App Bundle (`.aab`) will be created. The file you need is named **Monochrome6432.aab**. Transfer this file from your linux system to whatever system you use for web access (if not the linux system).

## 8. Uploading and Installing the App on Your Vehicle

### 1. Upload to Play Console

Log into your [Google Play Console](https://play.google.com/console) account.

- After verifying your ID, click **Create app**.
- Fill out the app name and mark it as a **free app**.

### 2. Add Automotive OS Form Factor

- Go to the **Internal testing** page (under **Test and release**).
- Click under **Phones, Tablets, Chrome OS** and go to **Manage form factors**.
- Add the **Android Automotive OS** form factor.
- Go to the **manage** button for Android Automotive OS and change it to use a **dedicated release track**.

### 3. Create New Release

- Go back to the **Internal testing** tab under **Test and release**.
- Create a new release under the **Automotive OS only** track.
- Upload the **Monochrome6432.aab** file to the app bundles section.
- Fill out the release information (e.g., version number).
- Go to the next screen and **publish the app**. (It may show some errors, but this is often fine for internal testing.)
  - **Note:** You may need to set a privacy policy. A random website URL can be used as a placeholder.

### 4. Internal Testing Invite

- Go back to the **Internal testing** section and create an email list.
- Add your email address to the list so you can accept the Internal Testing invitation.
- Copy the invite link and click **accept invite** to enable internal testing on your Google account.

### 5. Install on Vehicle

- In your vehicle, go to the search function in the Google Play Store.
- Search for the app using the unique identifier you set for **CHANGEME** in Step 6 (this is your package name).
- The result should appear without an app icon. Select it and install.

---

**You have successfully installed the compiled Chromium app onto your vehicle! Please use it responsibly and do not operate it to watch videos or movies while driving.**
