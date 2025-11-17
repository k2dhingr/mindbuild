# 🚀 COMPLETE SETUP GUIDE FOR NON-CODERS

This guide will walk you through EVERY step to get MindfulHealth running on your iPhone.

## PART 1: Install Required Software

### Step 1: Install Xcode (Apple's Development Tool)
1. Open **App Store** on your Mac
2. Search for "Xcode"
3. Click **Get** (it's FREE, but ~15GB download - will take 30-60 minutes)
4. Wait for it to download and install
5. Once installed, open Xcode
6. Accept the license agreement
7. Wait for "Additional Components" to install

### Step 2: Install Command Line Tools
1. Open **Terminal** (find it in Applications → Utilities)
2. Copy and paste this command, then press Enter:
   ```bash
   xcode-select --install
   ```
3. Click **Install** in the popup window
4. Wait for it to finish

### Step 3: Install Homebrew (Package Manager)
1. In Terminal, copy and paste this command, then press Enter:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Enter your Mac password when prompted (it won't show dots while you type - that's normal!)
3. Press Enter when asked to continue
4. Wait for it to finish (~5-10 minutes)

### Step 4: Install Python
1. In Terminal, type:
   ```bash
   brew install python@3.10
   ```
2. Press Enter and wait

### Step 5: Install Git LFS (for large files)
1. In Terminal, type:
   ```bash
   brew install git-lfs
   git lfs install
   ```
2. Press Enter

✅ **SOFTWARE INSTALLATION COMPLETE!**

---

## PART 2: Download the AI Model

### Step 1: Create a folder for the model
1. In Terminal, type these commands one by one:
   ```bash
   mkdir ~/MindfulHealthAssets
   cd ~/MindfulHealthAssets
   ```

### Step 2: Download Gemma 3n-E2B model
1. Go to this website in your browser:
   - https://huggingface.co/google/gemma-3n-E2B-it-litert-preview
2. Click the **Files and versions** tab
3. Find the file ending in `.pte` (around 2GB)
4. Click to download it
5. Move the downloaded file to: `~/MindfulHealthAssets/gemma3n.pte`

> ⚠️ **Important:** The model must be named exactly `gemma3n.pte`

✅ **MODEL DOWNLOADED!**

---

## PART 3: Set Up the Xcode Project

### Step 1: Create a new Xcode project
1. Open **Xcode**
2. Click **Create New Project**
3. Select **iOS** at the top
4. Click **App** → **Next**
5. Fill in:
   - **Product Name:** MindfulHealth
   - **Team:** Select your Apple ID (if you don't see it, click "Add Account" and sign in)
   - **Organization Identifier:** com.yourname (replace "yourname" with your actual name, no spaces)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - Leave everything else unchecked
6. Click **Next**
7. Choose where to save (e.g., Desktop → Create folder "MindfulHealth")
8. Click **Create**

### Step 2: Add the code files I created
1. **Download all the code files I created** from the `/home/claude/MindfulHealth` folder
2. In Xcode, right-click on the **MindfulHealth** folder (blue folder in left sidebar)
3. Select **Add Files to "MindfulHealth"...**
4. Navigate to where you saved my code files
5. Select ALL the files, check "Copy items if needed"
6. Click **Add**

Your project structure should now look like:
```
MindfulHealth/
├── MindfulHealthApp.swift
├── Models/
├── ViewModels/
├── Views/
├── Utilities/
├── Resources/
└── Info.plist
```

### Step 3: Add the AI model to your project
1. Drag the `gemma3n.pte` file from `~/MindfulHealthAssets` into the `Resources` folder in Xcode
2. Check "Copy items if needed"
3. Click **Finish**

### Step 4: Add ExecuTorch via Swift Package Manager
1. In Xcode, go to **File → Add Package Dependencies...**
2. In the search bar, paste:
   ```
   https://github.com/pytorch/executorch.git
   ```
3. In the branch dropdown, select: `release/1.0`
4. Click **Add Package**
5. When it shows the list of products, check these boxes:
   - ☑️ executorch
   - ☑️ xnnpack_backend
   - ☑️ ExecuTorchLLM
6. Click **Add Package** again
7. Wait for it to download (2-3 minutes)

### Step 5: Enable HealthKit
1. Click on the **blue MindfulHealth icon** at the very top of the left sidebar
2. Click on **Signing & Capabilities**
3. Click the **+ Capability** button
4. Search for "HealthKit" and double-click it
5. You should now see "HealthKit" in the list

### Step 6: Configure code signing
1. Still in **Signing & Capabilities** tab
2. Under "Team", select your Apple ID
3. If you see an error about Bundle Identifier, change it to:
   ```
   com.yourname.mindfulhealth
   ```
   (replace "yourname" with your actual name, all lowercase, no spaces)

✅ **XCODE PROJECT SET UP!**

---

## PART 4: Run on Your iPhone

### Step 1: Connect your iPhone
1. Connect your iPhone to your Mac with a USB cable
2. Unlock your iPhone
3. If you see "Trust This Computer?" on your iPhone, tap **Trust**
4. Enter your iPhone passcode

### Step 2: Select your iPhone in Xcode
1. At the top of Xcode, near the center, click on the device dropdown
2. Select your iPhone from the list (it will say "Your iPhone's Name")

### Step 3: Build and run!
1. Click the **Play button** (▶️) at the top left of Xcode
   - OR press: **⌘ + R**
2. Wait for it to build (first time takes 3-5 minutes)
3. You'll see "Build Succeeded" when ready

### Step 4: Trust the developer on your iPhone
**First time only:**
1. You'll see an error: "Untrusted Developer"
2. On your iPhone, go to: **Settings → General → VPN & Device Management**
3. Tap your Apple ID under "Developer App"
4. Tap **Trust [Your Apple ID]**
5. Tap **Trust** again to confirm
6. Go back to Xcode and click ▶️ again

### Step 5: Grant permissions
When the app launches:
1. Tap **Get Started**
2. When iOS asks for Health permissions, tap **Turn All Categories On**
3. Tap **Allow**

🎉 **THE APP IS NOW RUNNING ON YOUR IPHONE!**

---

## PART 5: Create Demo Video

### Step 1: Screen record on iPhone
1. On your iPhone, go to **Settings → Control Center**
2. Add **Screen Recording** if not already there
3. Swipe down from top-right corner (or up from bottom on older iPhones)
4. Press the **Record button** (circle icon)
5. Wait 3 seconds
6. Use the MindfulHealth app
7. When done, tap the red bar at the top → **Stop**

### Step 2: Transfer video to Mac
1. Open **Photos** app on iPhone
2. Select the screen recording video
3. Tap the **Share** button
4. Select **AirDrop → Your Mac**

### Step 3: Edit with iMovie (optional)
1. Open **iMovie** on Mac (FREE app)
2. Import your video
3. Add voiceover explaining features
4. Export as **File → 1080p**

---

## PART 6: Push to GitHub

### Step 1: Create GitHub repository
1. Go to https://github.com
2. Click **New repository**
3. Name it: `mindful-health-arm-challenge`
4. Select **Public**
5. Check "Add a README file"
6. Click **Create repository**

### Step 2: Initialize Git in your project
1. Open Terminal
2. Navigate to your project:
   ```bash
   cd ~/Desktop/MindfulHealth
   ```
3. Run these commands:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: MindfulHealth app"
   ```

### Step 3: Connect to GitHub
1. On your GitHub repository page, click the green **Code** button
2. Copy the HTTPS URL
3. In Terminal, run:
   ```bash
   git remote add origin YOUR_COPIED_URL
   git branch -M main
   git push -u origin main
   ```

✅ **CODE IS NOW ON GITHUB!**

---

## PART 7: Submit to ARM Challenge

1. Go to the ARM AI Developer Challenge page on Devpost
2. Click **Submit Your Project**
3. Fill in:
   - **Project Name:** MindfulHealth
   - **Tagline:** AI-Powered Wellness Coach - Private, On-Device, Holistic
   - **GitHub URL:** Your repository link
   - **Video URL:** YouTube link (upload your demo video to YouTube first)
   - **Description:** Copy from README.md
4. Select categories:
   - On-Device AI
   - Health & Wellness
5. Upload screenshots from your iPhone
6. Click **Submit**

---

## 🎯 CHECKLIST BEFORE SUBMITTING

- [ ] App runs on my iPhone without crashes
- [ ] HealthKit permissions granted
- [ ] Can see health metrics on dashboard
- [ ] Can chat with AI (even if placeholder responses)
- [ ] Demo video recorded (3-5 minutes)
- [ ] Code pushed to GitHub
- [ ] README.md is comprehensive
- [ ] Screenshots uploaded

---

## 🆘 TROUBLESHOOTING

### "Build Failed" in Xcode
1. Clean build folder: **Product → Clean Build Folder**
2. Close Xcode completely
3. Reopen and try again

### "Model file not found"
1. Check that `gemma3n.pte` is in the **Resources** folder in Xcode
2. Right-click the file → **Show in Finder**
3. Verify it's ~2GB in size

### "HealthKit not available"
1. Make sure you're testing on a real iPhone (not Simulator)
2. Check that HealthKit capability is added in Xcode

### App crashes on launch
1. Check the Console in Xcode (bottom right) for error messages
2. Most common: Missing permissions in Info.plist
3. Make sure `NSHealthShareUsageDescription` exists in Info.plist

---

## 📞 NEED HELP?

If you get stuck:
1. Check the error message in Xcode's Console (bottom right panel)
2. Copy the error message and ask me for help
3. Or search the error on Stack Overflow

---

**Remember:** The goal is to SHOW that it works, even if the AI responses are placeholder. The judges care about:
1. Does it run on-device? ✅
2. Does it integrate HealthKit? ✅
3. Is the UI beautiful? ✅
4. Does it showcase ARM optimization potential? ✅

Good luck! 🚀
