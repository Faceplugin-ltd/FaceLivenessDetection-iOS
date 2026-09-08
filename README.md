<div align="center">
<img alt="FacePlugin" src="https://avatars.githubusercontent.com/u/160751046?s=200&v=4" width="200"/>
</div>

#### 🌐 Company Site - [Here](https://faceplugin.com)
#### 🤗 Hugging Face - [Here](https://huggingface.co/FacePlugin-Ltd)
#### 🛟 Help Center - [Here](https://doc.faceplugin.com)
#### 🐳 Docker Hub - [Here](https://hub.docker.com/u/faceplugin)

# FacePlugin Face Liveness Detection SDK — iOS (Fully On-Premise)

> **Ready in ~10 minutes (after framework download):**
> Unzip Drive frameworks into this folder → Run on a phone
> Jump: [Quick start](#quick-start-checklist) · [Get the framework](#get-the-framework) · [Run the demo](#run-the-demo) · [Setup](#setup-on-your-own-app) · [About SDK](#about-sdk)

## Quick start checklist

- [ ] Clone `https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS`
- [ ] Download the `.zip` files from [Google Drive](#get-the-framework)
- [ ] Unzip into this folder (`facelivenessdk.framework`, `FaceLivenessEngine.framework`, `onnxruntime.framework`)
- [ ] Open `FaceLivenessSDK.xcodeproj` → set **your** Team → Run on a **physical** iPhone
- [ ] Home status shows ready → **Liveness / Settings / About** unlock

> **Your own app?** Skip to [Setup on your own app](#setup-on-your-own-app). Full API: [doc.faceplugin.com](https://doc.faceplugin.com).

## Introduction

FacePlugin **Face Liveness Detection SDK for iOS** is a fully on-device anti-spoofing engine for KYC and remote identity verification. **iBeta level 2–class** passive liveness detects printed photos, video replay, 3D masks, and deepfake-style attacks — no extra hardware, no cloud.

All processing stays on the iPhone. **No** biometric data leaves the device.

This repository is the **iOS demo app**. Runtime frameworks download from Google Drive. No other FacePlugin repository is required.

### Main Functionalities

| Demo tile | What it does |
| --------- | ------------ |
| **Liveness** | Live camera anti-spoofing with face overlay + liveness metrics |
| **Settings** | Camera lens, liveness threshold |
| **About** | FacePlugin Face Liveness SDK — on-device anti-spoofing |

### Product List

| Platform | Repository |
|----------|------------|
| Android (Recognition) | [FaceRecognition-Android](https://github.com/Faceplugin-ltd/FaceRecognition-Android) |
| iOS (Recognition) | [FaceRecognition-iOS](https://github.com/Faceplugin-ltd/FaceRecognition-iOS) |
| React Native (Recognition) | [FaceRecognition-React-Native](https://github.com/Faceplugin-ltd/FaceRecognition-React-Native) |
| Flutter (Recognition) | [FaceRecognition-Flutter](https://github.com/Faceplugin-ltd/FaceRecognition-Flutter) |
| Ionic Capacitor (Recognition) | [FaceRecognition-Ionic-Capacitor](https://github.com/Faceplugin-ltd/FaceRecognition-Ionic-Capacitor) |
| Ionic Cordova (Recognition) | [FaceRecognition-Ionic-Cordova](https://github.com/Faceplugin-ltd/FaceRecognition-Ionic-Cordova) |
| Windows (Recognition) | [FaceRecognition-Windows](https://github.com/Faceplugin-ltd/FaceRecognition-Windows) |
| Linux / Docker (Recognition) | [FaceRecognition-Docker](https://github.com/Faceplugin-ltd/FaceRecognition-Docker) |
| Android (Liveness) | [FaceLivenessDetection-Android](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Android) |
| **iOS (Liveness)** | **[FaceLivenessDetection-iOS](https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS)** (**this repo**) |
| Windows (Liveness) | [FaceLivenessDetection-Windows](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Windows) |
| Linux / Docker (Liveness) | [FaceLivenessDetection-Docker](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Docker) |


## Before you start

| Step | What you need |
| ---- | ------------- |
| 1 | Xcode 15+ and a **physical iPhone** |
| 2 | Unzipped frameworks in this folder — see [Get the framework](#get-the-framework) |
| 3 | Demo license is already in the repo for `com.faceplugin.facelivenessdk`. Request a new key only if you change bundle id — see [SDK License](#sdk-license) |

### System requirements

| Item | Minimum | Recommended |
| ---- | ------- | ----------- |
| iOS | 13.0 | 16 or newer |
| Device | Physical iPhone | Same; simulator is not for camera / liveness |

## Get the framework

Frameworks are stubs on GitHub because the binaries are too large. On Drive they ship as **zips** — unzip after download.

### Where to download

**[FaceLivenessSDK iOS (Google Drive)](https://drive.google.com/drive/folders/1HzREOmFg9kBLbuso1e57j8Hk5Jk41kyr)** — `facelivenessdk.framework.zip`, `FaceLivenessEngine.framework.zip`, `onnxruntime.framework.zip`

### How to place it

```bash
git clone https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS.git
cd FaceLivenessDetection-iOS
```

Unzip and place frameworks at the **repo root** (next to `FaceLivenessSDK.xcodeproj`):

```text
FaceLivenessDetection-iOS/
├── FaceLivenessSDK.xcodeproj
├── FaceLivenessKit/
├── FaceLivenessSDK/
├── facelivenessdk.framework/
├── FaceLivenessEngine.framework/
└── onnxruntime.framework/
```

## Run the demo

1. Open **FaceLivenessSDK.xcodeproj** in Xcode.
2. Set your **Team** for signing.
3. Run on a device. The demo already has a valid `licenseKey` for `com.faceplugin.facelivenessdk`.

Keep bundle id **`com.faceplugin.facelivenessdk`** for the included license.

### Screenshots

| Home | Liveness | Settings | About |
| ---- | -------- | -------- | ----- |
| <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/home.png" alt="FacePlugin Face Liveness — Home with Liveness, Settings, About" width="220"/></p> | <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/liveness.png" alt="FacePlugin Face Liveness — live camera anti-spoofing with face box and metrics" width="220"/></p> | <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/settings.png" alt="FacePlugin Face Liveness — Settings for camera lens and liveness threshold" width="220"/></p> | <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/about.png" alt="FacePlugin Face Liveness SDK — About, on-device anti-spoofing" width="220"/></p> |

## SDK License

Licenses are **offline** and bound to your bundle identifier.

The sample app already includes a valid key for `com.faceplugin.facelivenessdk`. You only need a new key if you use a different bundle identifier.

### How to get a license

The code below shows how to use the license:

[https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS/blob/1e546a4b446fbf6f2139726aeeb9213c2949c38b/FaceLivenessSDK/Home/ViewController.swift#L7-L8](https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS/blob/1e546a4b446fbf6f2139726aeeb9213c2949c38b/FaceLivenessSDK/Home/ViewController.swift#L7-L8)

[https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS/blob/1e546a4b446fbf6f2139726aeeb9213c2949c38b/FaceLivenessSDK/Home/ViewController.swift#L136-L148](https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS/blob/1e546a4b446fbf6f2139726aeeb9213c2949c38b/FaceLivenessSDK/Home/ViewController.swift#L136-L148)

Please [contact us](#contact) to get a license for **your own app**.

## Setup on your own app

Minimal integration (details: [doc.faceplugin.com](https://doc.faceplugin.com)):

1. Add `facelivenessdk.framework`, `FaceLivenessEngine.framework`, and `onnxruntime.framework` (Embed & Sign).
2. Optionally copy **FaceLivenessKit** for `FaceLivenessClient` helpers.
3. Activate once at launch (off the main thread): `FaceLivenessClient.shared.activate(license: "FP1.…") { code in … }` (`0` = success).
4. Add `NSCameraUsageDescription` in `Info.plist`.

Request a license for **your** bundle id, not the demo’s.

## About SDK

Use **FaceLivenessKit** (`FaceLivenessClient.shared`) or call the native SDK from Objective-C++. Call **once per process**: activate → init. Serialize native work. Full reference: [doc.faceplugin.com](https://doc.faceplugin.com).

| Code | Meaning |
| ---- | ------- |
| 0 | Success |
| 1 | License invalid |
| 2 | License expired |
| 3 | Not activated |
| 4 | Init failed |

## Contact

<div align="left">
<a target="_blank" href="mailto:info@faceplugin.com"><img src="https://img.shields.io/badge/email-info@faceplugin.com-blue.svg?logo=gmail" alt="faceplugin.com"></a>&emsp;
<a target="_blank" href="https://wa.me/+14692784822"><img src="https://img.shields.io/badge/whatsapp-faceplugin-blue.svg?logo=whatsapp" alt="faceplugin.com"></a>
</div>
