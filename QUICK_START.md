# Quick Start Guide

This guide is designed to get you up and running with the DocLock iOS project as quickly as possible, even if you are new to iOS development.

## Modifications Required
You will need a Mac with **Xcode** installed.

## Step 1: Clone the Project
Open your Terminal and run:

```bash
git clone <repository-url>
cd docLockIOS
```

## Step 2: Open in Xcode
Find the file named `docLock.xcodeproj` in the folder and double-click to open it.

## Step 3: Add Configuration File
**Important:** You need a file called `GoogleService-Info.plist` to run the app. Ask the person who gave you access for this file.

1.  Once you have the file, drag and drop it into the left sidebar of Xcode (the project navigator), right under the top-level `docLock` folder.
2.  A popup will appear. Make sure **"Copy items if needed"** is checked and click **Finish**.

## Step 4: Fix Signing & Bundle ID
Since you don't have access to the original developer team account, you need to use your own "signature".

1.  In Xcode, click on the **blue project icon** (`docLock`) at the very top of the left sidebar.
2.  Click on **docLock** under the "TARGETS" section in the middle pane.
3.  Click on the **"Signing & Capabilities"** tab at the top.
4.  **Team:** Select your "Personal Team" from the dropdown (you might need to log in with your Apple ID in Xcode -> Settings -> Accounts).
5.  **Bundle Identifier:** Change this to something unique.
    *   *Current:* `com.techvriksha.doclock`
    *   *Change to:* `com.techvriksha.doclock.yourname` (replace `yourname` with your actual name).

## Step 5: Run the App
1.  Connect your iPhone via USB, or select a Simulator (like "iPhone 16") from the top bar in Xcode.
2.  Press the **Play** button (▶️) at the top left or press `Cmd + R` on your keyboard.
3.  The app should install and open on your device/simulator!

---
*For more detailed troubleshooting, see [TEAM_SETUP_GUIDE.md](TEAM_SETUP_GUIDE.md)*
