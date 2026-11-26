<div align="center">
<img alt="FacePlugin" src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/brand/logo.png" width="400"/>
</div>

#### 🌐 Company Site - [Here](https://faceplugin.com)
#### 🤗 Hugging Face - [Here](https://huggingface.co/FacePlugin-Ltd)
#### 🛟 Help Center - [Here](https://doc.faceplugin.com)
#### 🐳 Docker Hub - [Here](https://hub.docker.com/u/faceplugin)

# FacePlugin Face Liveness Detection — iOS (Fully On-Premise)

> **Ready in ~10 minutes (after the framework download):**
> Unzip the four engine bundles into this folder → Run on a phone
> Jump: [Quick start](#quick-start-checklist) · [Get the frameworks](#get-the-frameworks) · [Run the demo](#run-the-demo) · [Active liveness](#active-liveness) · [Setup](#setup-on-your-own-app) · [About SDK](#about-sdk)

## Quick start checklist

- [ ] Clone `FaceLivenessDetection-iOS`
- [ ] Download the four engine bundles — see [Get the frameworks](#get-the-frameworks)
- [ ] Unzip them into this folder (`facerecognitionsdk.framework`, `FacePluginSDK.xcframework`, `FacePlugin.xcframework`, `FaceDetect.xcframework`)
- [ ] Open `FaceLivenessSDK.xcodeproj` → select scheme **FaceLivenessDetectioniOS** → set **your** Team
- [ ] Prefer a **USB** iPhone (Wi‑Fi debug often hangs LLDB). Or: `python3 run_ios`
- [ ] Home status shows **Ready** → **Active liveness / Passive liveness** unlock

> **Your own app?** Skip to [Setup on your own app](#setup-on-your-own-app). Full API: [doc.faceplugin.com](https://doc.faceplugin.com).

## Introduction

FacePlugin **Face Liveness Detection SDK for iOS** is a fully on-device anti-spoofing engine for KYC and remote identity verification. It detects printed photos, video replay, 3D masks, and deepfake-style attacks — no extra hardware, no cloud.

It runs liveness two ways, and this demo app ships both:

- **Passive** — the engine scores a single frame. Nothing is asked of the user.
- **Active** — the face is scored for spoofing **first**, and only a face that clears that gate is asked for a short sequence of actions (blink, smile, turn your head). A recorded video cannot answer a sequence it has never seen, so the two together are the stronger check against replay.

All processing stays on the iPhone. **No** biometric data leaves the device.

This repository is the whole product: the **engine** (four bundles you download), a **kit** that owns the engine lifecycle, the **active-liveness screen**, and a **demo app** built from them — so what you read here is what the demo runs. The engine is the same build the [FaceRecognition-LivenessDetection-iOS](https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-iOS) demo uses, and it mirrors the Android `facerecognitionsdk.aar`.

### What is in here

| Group | What it is |
| ----- | ---------- |
| `FaceLivenessKit/` | Engine lifecycle, serialized SDK calls, camera frames, per-frame face attributes (`FaceEngine.shared`) |
| `FaceLivenessSDK/ActiveLiveness/` | The guided active-liveness screen: anti-spoofing gate, then the challenges, returned as a result |
| `FaceLivenessSDK/` | The demo app, built from those |
| `FaceLivenessBridge/` | An `@objc` face on the same screens, for hosts that cannot read a Swift interface — see [Non-Swift hosts](#non-swift-hosts) |

### Main Functionalities

| Demo tile | What it does |
| --------- | ------------ |
| **Active liveness** | Anti-spoofing gate, then a guided challenge sequence — face frame, progress ring, per-step instructions, and a pass/fail result listing every check |
| **Passive liveness** | Live camera anti-spoofing with a face box and a liveness / quality / pose HUD |
| **Settings** | Camera lens, the challenge pool and how many are asked, random order, engine thresholds, passive score threshold |
| **About** | FacePlugin Face Liveness SDK — on-device anti-spoofing |

### Product List

| Platform | Repository |
| -------- | ---------- |
| Android | [FaceLivenessDetection-Android](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Android) |
| **iOS** | **[FaceLivenessDetection-iOS](https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS)** **(this repo)** |
| React Native | [FaceLivenessDetection-ReactNative](https://github.com/Faceplugin-ltd/FaceLivenessDetection-ReactNative) |
| Flutter | [FaceLivenessDetection-Flutter](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Flutter) |
| .NET MAUI | [FaceLivenessDetection-DotNet-MAUI](https://github.com/Faceplugin-ltd/FaceLivenessDetection-DotNet-MAUI) |
| Ionic Cordova | [FaceLivenessDetection-Ionic-Cordova](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Ionic-Cordova) |
| Ionic Capacitor | [FaceLivenessDetection-Ionic-Capacitor](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Ionic-Capacitor) |
| Windows | [FaceLivenessDetection-Windows](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Windows) |
| Linux / Docker | [FaceLivenessDetection-Docker](https://github.com/Faceplugin-ltd/FaceLivenessDetection-Docker) |

### Related products

- **Face Recognition + Liveness — iOS** — [FaceRecognition-LivenessDetection-iOS](https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-iOS) — recognition + liveness + attributes
- **Face Recognition + Liveness — Android** — [FaceRecognition-LivenessDetection-Android](https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-Android) — recognition + liveness + attributes
- **Face Recognition — Windows** — [FaceRecognition-Windows](https://github.com/Faceplugin-ltd/FaceRecognition-Windows) — on-premise server
- **Face Recognition — Docker** — [FaceRecognition-Docker](https://github.com/Faceplugin-ltd/FaceRecognition-Docker) — on-premise server


## Before you start

| Step | What you need |
| ---- | ------------- |
| 1 | Xcode 15+ and a **physical iPhone** |
| 2 | The four engine bundles in this folder — see [Get the frameworks](#get-the-frameworks) |
| 3 | Demo license is already in the repo for `com.faceplugin.faceliveness.app`. Request a new key only if you change bundle id — see [SDK License](#sdk-license) |

### System requirements

| Item | Minimum | Recommended |
| ---- | ------- | ----------- |
| iOS | 15.0 | 16 or newer |
| Device | Physical iPhone | Same; the engine ships no simulator slice |

## Get the frameworks

The bundles are stubs on GitHub because the binaries are too large. The engine is the Face Recognition engine build — the same one the Android app loads as `facerecognitionsdk.aar`.

### Where to download

**[Download the engine from Releases](https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-iOS/releases/tag/latest)** — `facerecognitionsdk.framework`, `FacePluginSDK.xcframework`, `FacePlugin.xcframework`, `FaceDetect.xcframework`

All four are **device only** (`ios-arm64`), which is why the app runs on a physical iPhone and not in the simulator.

> **The double-P slice.** Inside `FacePlugin.xcframework` the `ios-arm64` slice is named **`FacePPlugin.framework`**, with two Ps. That is deliberate, not a typo — linker flags and any host that embeds the slice directly must use that name.

### How to place them

```bash
git clone https://github.com/Faceplugin-ltd/FaceLivenessDetection-iOS.git
cd FaceLivenessDetection-iOS
```

Place the bundles at the **repo root** (next to `FaceLivenessSDK.xcodeproj`):

```text
FaceLivenessDetection-iOS/
├── FaceLivenessSDK.xcodeproj
├── FaceLivenessKit/
├── FaceLivenessSDK/
├── FaceLivenessBridge/
├── facerecognitionsdk.framework/
├── FacePluginSDK.xcframework/
├── FacePlugin.xcframework/
└── FaceDetect.xcframework/
```

## Run the demo

1. Open **FaceLivenessSDK.xcodeproj** in Xcode.
2. Select scheme **FaceLivenessDetectioniOS** and set your **Team** for signing.
3. Prefer a **USB** cable. The shared scheme runs **without LLDB** (Wi‑Fi + debugger often hangs ~6 minutes then fails with “LLDB RPC Server has exited”).
4. Or deploy without Xcode: `python3 run_ios`.

Keep bundle id **`com.faceplugin.faceliveness.app`** for the included license. The app product is **FaceLivenessDetectioniOS** (home-screen name **Face Liveness**).

### Screenshots

| Active liveness(Result) | Passive liveness |
| ----------------- | ------------------ |
| <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/active_result.png" alt="FacePlugin Face Liveness — Active liveness result: anti-spoofing gate and challenges passed" width="220"/></p> | <p align="center"><img src="https://raw.githubusercontent.com/Faceplugin-ltd/faceplugin-assets/main/screenshots/face-liveness/mobile/passive.png" alt="FacePlugin Face Liveness — Passive liveness: live camera anti-spoofing with liveness, quality and pose" width="220"/></p> |

## Active liveness

Open **Active liveness** on the home screen. One attempt runs in three stages, in this order:

1. **Align** — one face, framed well enough to be scored.
2. **Passive anti-spoofing gate** — the face is scored and a few frames are averaged. Below the
   threshold the attempt ends here and **no challenge is asked**: a printed photo or a replayed
   video is never invited to blink.
3. **Challenges** — a shuffled sequence of actions over the face frame, with a progress ring and
   per-step instructions.

It ends on a result card listing the gate and every challenge with its outcome, how long the attempt
took, and the passive score the gate measured.

**Losing the face starts the attempt over.** Gone from the frame for about a second and everything
resets to stage one, the gate included, so no attempt can be half-completed by one face and finished
by another. `ActiveLivenessResult` is only ever produced for an attempt run end to end by one face.

### When a face cannot be checked

A face in front of the camera is not always one the engine can score. Rather than leaving the user
holding still against a frame that will never pass, the screen names what is wrong — these are the
`ActiveLivenessSession.Notice` cases:

| On screen | What the frame shows |
| --------- | -------------------- |
| Move closer | The face fills less of the frame than **Minimum face size** |
| Move back a little | The face runs past the edge of the frame, or nearly fills it |
| Move your face into the middle | The face is well off centre |
| Look straight at the camera | Yaw, pitch or roll is beyond **Start alignment tolerance** |
| Too dark or blurry | The engine's own image quality is below **Minimum image quality** |
| Cannot read your face | Well framed, and the engine still returned no liveness score |
| Only one face, please | More than one face is in the frame |

These are checked in the order a person would fix them, and only while the face is being framed and
scored — a challenge deliberately turns the head away, so the pose and quality checks step aside
once the challenges start. Both thresholds are editable under **Settings → Active liveness**.

### Using it in your app

The screen is one view controller, presented with a completion:

```swift
ActiveLivenessViewController.present(from: self, options: ActiveLivenessOptions()) { result in
    guard let result else { return }          // closed before it finished
    if result.passed {
        // live person
    } else if !result.passivePassed {
        // turned away at the anti-spoofing gate
    } else {
        // a challenge was not completed: result.failedCheck
    }
}
```

`FaceEngine.shared.start` has to have succeeded first — see [Setup](#setup-on-your-own-app).

### How the checks are judged

The engine scores a frame; it does not sequence anything. So the sequence lives in
`ActiveLivenessSession`, over the per-frame attributes the engine reports — the passive liveness
score drives the gate, `Pan` / `Tilt` in degrees drive the turn and tilt challenges, eye openness
drives blink, and the smile estimate drives smile.

| Stage | What it waits for |
| ----- | ----------------- |
| Align | One face, framed and square to the camera — the table above is what it checks |
| Gate | The average of **passive samples** scores reaching the **score threshold** |
| Each challenge | The condition below, held for two frames running |
| Restart | The face out of frame for about a second, at any stage past aligning |
| Fail | **Frames allowed per stage** elapse without the condition being met |

| Challenge | Satisfied when |
| --------- | -------------- |
| Blink | Eye openness drops to the eye-closed threshold and recovers, **Blinks required** times |
| Smile | The smile estimate reaches the smile threshold |
| Turn left / right | Yaw passes the turn angle in that direction |
| Look up / down | Pitch passes the tilt angle in that direction |
| Move closer | The face box grows by the move-closer fraction from where the challenge started |

Turning the wrong way is answered with a nudge rather than a silent failure, and every threshold is
editable under **Settings → Active liveness**. Defaults: **3** challenges drawn at random from
blink, smile, turn left, turn right, look up and look down; liveness threshold **0.5**; **3** passive
samples; **150** frames allowed per stage; yaw **25°**; pitch **15°**; smile **0.5**; blink **0.3**
with **2** blinks required; move-closer fraction **0.15**; align angle **12°**; minimum face fraction
**0.3**; quality threshold **0.3**.

> **Head-pose direction.** Which way is positive for yaw and pitch is a property of the engine build.
> If a turn challenge accepts the opposite direction on your device, flip **Settings → Invert left /
> right** (or **Invert up / down**) — no rebuild needed.

### Replay resistance

The gate runs before the challenges, and the sequence is shuffled on each attempt
(**Settings → Random order**), so the challenges and their order are not known ahead of time. Keep
both on in production: the result card reports the passive score and each challenge separately.

## SDK License

Licenses are **offline** and bound to your bundle identifier.

The sample app already includes a valid key for `com.faceplugin.faceliveness.app`. You only need a new key if you use a different bundle identifier.

> **This build changed engines.** The app now runs on `facerecognitionsdk.framework`, and that
> runtime checks licences with its own library. If the home status shows **Invalid license!** or
> **No activated!** on a clean install, the bundled key predates the change —
> [contact us](#contact) for one issued for `com.faceplugin.faceliveness.app` on this runtime.

### How to get a license

The demo holds its key in [`ViewController.swift`](FaceLivenessSDK/Home/ViewController.swift) and
hands it to `FaceEngine.shared.start`, which activates and initialises the engine off the main
thread:

```swift
FaceEngine.shared.start(license: LICENSE_KEY) { code in
    // code == 0 once the engine is ready
}
```

Please [contact us](#contact) to get a license for **your own app**.

### License capabilities

After activation, `FaceEngine.shared.licenseStatus()` reports what the key unlocks:

- **Liveness only** / **Recognition + Liveness** — both liveness tiles unlock
- **Recognition only** — liveness stays unavailable in this app
- **Not licensed** — the tiles stay locked until you activate

## Setup on your own app

Minimal integration (details: [doc.faceplugin.com](https://doc.faceplugin.com)):

1. Embed & Sign the four engine bundles: `facerecognitionsdk.framework`, `FacePluginSDK.xcframework`,
   `FacePlugin.xcframework` and `FaceDetect.xcframework`.
2. Add **FaceLivenessKit** for the engine lifecycle (`FaceEngine.shared`), and copy the
   `ActiveLiveness` group if you want the guided screen.
3. Activate once at launch — it runs off the main thread on its own:
   `FaceEngine.shared.start(license: "FP1.…") { code in … }` (`0` = success).
4. Add `NSCameraUsageDescription` to `Info.plist`.
5. Passive: call `FaceEngine.shared.detect(image, options:)` per frame. Active: present
   `ActiveLivenessViewController` for a result — see [Active liveness](#active-liveness).

Set **your** bundle identifier, and request a license for it rather than the demo’s.

## Non-Swift hosts

The screens above are Swift, and Swift-only API — structs, enums with associated values — is
invisible to Objective-C and therefore to anything that binds a framework through its generated
header: .NET MAUI, Xamarin, Unity, Cordova's Objective-C plugin API.

**FaceLivenessBridge** is the answer to that. It is a framework target in this project whose only
job is to put an `@objc` face on the same screens — `FPLEngine`, `FPLActiveOptions`,
`FPLActiveResult`, `FPLLiveness`, all `NSObject`s and `Int`-backed enums. It adds no behaviour: the
engine is still `FaceEngine`, the screens are still `ActiveLivenessViewController` and
`LivenessCameraViewController`, and the target compiles the *same source files* the app does rather
than copies of them, so the two cannot drift.

```bash
./scripts/build_bridge.sh            # → build/xcframeworks/
```

That produces `FaceLivenessBridge.xcframework` and `FaceLivenessKit.xcframework`, which a host
embeds along with the four engine bundles. **Device only** (`ios-arm64`): the engine ships no
simulator slice, which is the same reason the app itself only runs on a physical phone.

The wire values it reports — challenge keys, outcome and failure names — are the ones Android uses,
so a cross-platform host can treat both platforms identically.
[FaceLivenessDetection-DotNet-MAUI](https://github.com/Faceplugin-ltd/FaceLivenessDetection-DotNet-MAUI)
is built on it.

Objective-C and Swift apps should use `FaceLivenessKit` and the screens directly; the bridge exists
only for hosts that cannot read a Swift interface.

## About SDK

Use **FaceLivenessKit** (`FaceEngine.shared`) or call the native SDK from Objective-C++. The engine class is `FaceRecognitionSDK`, from `facerecognitionsdk.framework` — the iOS counterpart of the Android app's `libs/facerecognitionsdk.aar`. Activate once at start-up, then call the engine. The first start loads the on-device models, so it takes a few seconds. Keep every later call on one thread: the engine is not concurrent, and the kit serializes for you. Full reference: [doc.faceplugin.com](https://doc.faceplugin.com).

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
<a target="_blank" href="https://t.me/FacePluginSupport"><img src="https://img.shields.io/badge/telegram-@FacePluginSupport-blue.svg?logo=telegram" alt="Telegram @FacePluginSupport"></a>&emsp;
<a target="_blank" href="https://wa.me/+14692784822"><img src="https://img.shields.io/badge/whatsapp-faceplugin-blue.svg?logo=whatsapp" alt="faceplugin.com"></a>
</div>
