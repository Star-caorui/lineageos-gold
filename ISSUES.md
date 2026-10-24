# Issues

Every known issue and request on LineageOS 24.0 for gold, in one place: the ones reported in Telegram, and the ones found while working on the trees, under Betterr. Newest first.

Status: Merged (fixed in a release), Fixing, Open (confirmed, not started), Upstream review (patch sent upstream, not in our builds), Need info, Not tested, Not planned, Not a bug, Not possible.

| Issue | Reporter | Date | Status | Notes |
| --- | --- | --- | --- | --- |
| The stock battery driver reports a cycle count in the thousands | Betterr | 2026-10-17 | Open | 1668 on the test unit and 4519 on ukriu's. The driver is now built from source the way stock builds it, and reports the same. Shown as is in the device diagnostics. |
| Multitasking lags below 30 % battery | yuuki | 2026-10-17 | Open |  |
| UI lags right after leaving a game | yuuki | 2026-10-17 | Open |  |
| Stock init scripts make some device nodes and camera files world-writable | Betterr | 2026-10-16 | Open | 0666 and 0777 copied from stock; SELinux still limits access. Tightening them needs each feature tried on a phone. |
| Bluetooth call uses the phone's microphone instead of the earbuds' | ukriu | 2026-10-16 | Need info |  |
| LDAC limited to 16 bits per sample | ukriu | 2026-10-15 | Need info |  |
| NFC turns on but does not read anything | affan | 2026-10-15 | Need info |  |
| Dolby Atmos | Thakur | 2026-10-15 | Not planned | Stock's effect libraries (Dolby, MiSound, spatial audio) are not included. |
| User build to pass Play Integrity | Thakur | 2026-10-15 | Not planned |  |
| Sunlight mode | yuuki | 2026-10-15 | Not possible | The panel has one brightness range, and its upper half is the high brightness mode that auto-brightness already uses. |
| Fast charging settles at 8–10 W | ukriu | 2026-10-14 | Open | With the screen on, Xiaomi's thermal daemon raises the charging thermal level. Stock switches it between scene profiles; nothing does here, so it stays on the default one. With the daemon stopped it held about 20 W. |
| 24 fps video stays at 60 Hz instead of 120 Hz | ukriu | 2026-10-14 | Need info | A 24 fps video in Glimpse played at 120 Hz on the test unit, with `debug.sf.frame_rate_multiple_threshold=120` and without it. Which player, and how was 60 Hz seen? |
| Status bar updates push the refresh rate back to 120 Hz | ukriu | 2026-10-14 | Not planned |  |
| Charger-connected vibration is too long | ukriu | 2026-10-14 | Not a bug |  |
| Vibration intensity slider | ukriu | 2026-10-14 | Not planned |  |
| Freeform windows | ukriu | 2026-10-14 | Not planned |  |
| Writes to the other slot after an OTA are lost on reboot | ukriu | 2026-10-14 | Not planned |  |
| Offline charging loops on the Redmi logo when an alarm is set | Betterr | 2026-10-14 | Open | Seen on the test unit only. On 2026-10-19 the loop did not come back with an alarm set, but entering offline charging took one or two restarts more than the usual one. Cause not found; the reset leaves no crash record. |
| WCDMA does not work | ukriu | 2026-10-14 | Not a bug |  |
| Game space | yuuki | 2026-10-14 | Not planned |  |
| Leica / HyperOS camera modules show a black preview | Asnalstan, yuuki | 2026-10-14 | Not planned | The app looks up a constructor of `StreamConfigurationMap` that only Android 14 had. Adding it back takes two patches to `frameworks/base`, as crDroid, Lunaris and AxionOS carry; we do not. |
| Flashlight strength control | Thakur | 2026-10-14 | Not planned |  |
| Fast charging on units with the LN8000 charge pump | Betterr | 2026-10-14 | Not tested | Tested on a unit with the SC8551 only. |
| Video calls | Betterr | 2026-10-14 | Not tested |  |
| Game-mode touch tuning | Betterr | 2026-10-14 | Not planned | Driven by Xiaomi's `touchfeature` service, which is not included. |
| DC dimming and colour modes | Betterr | 2026-10-14 | Open | Stock's come from Xiaomi's `displayfeature` service. Here they would need a small LiveDisplay service writing panel nodes under `/sys/class/mi_display/disp-DSI-0/`; nobody has tried what writing them does. |
| Two SELinux denials logged now and then: the positioning daemon reading a property, the media provider at the root directory | Betterr | 2026-10-13 | Open | No effect seen. Not traced. |
| Decoding several DNG files at once can crash the app (a race in AOSP's DNG library) | Betterr | 2026-10-13 | Not planned | About once in twenty tries with four threads. Not patched. |
| Screen lock cannot be set after setup (FRP) | ukriu | 2026-10-13 | Merged (2026101303) | Factory reset protection is left off: a build without Google apps cannot clear what a Google-equipped system left on the FRP partition. With the bootloader unlocked, `fastboot erase frp` removes it. |
| Bluetooth tethering does not connect | ukriu | 2026-10-13 | Need info |  |
| Dual SIM | Betterr | 2026-10-13 | Not tested |  |
| China Telecom SIM | Betterr | 2026-10-13 | Not tested |  |
| "Hey Google" with the screen off | Betterr | 2026-10-13 | Not tested | The sound trigger HAL and the enrollment apps are stock's and in place; trying it needs the Google app. |
| 108 MP, portrait and 16 MP front photos | Betterr | 2026-10-13 | Not planned | The camera HAL offers them only to the stock camera app, so the rear camera gives 12 MP and the front 4 MP. |
| Stronger video stabilisation | Betterr | 2026-10-13 | Not planned | It takes a patch to the camera app. |
| More screen-off gestures (swipes, letters) | Betterr | 2026-10-13 | Open | Double tap and single tap are offered. The FocalTech driver also lists swipes and letters; nobody has checked that the firmware reports them. |
| 200 % speaker volume | Betterr | 2026-10-13 | Open | Stock's MIUI framework sends `SpkVolIdx` and `SuperStream` past the top step to switch the amplifier's scene; nothing in LineageOS sends them. Only units with the AW87xxx amplifier could show an effect. |
| Xiaomi and Alexa wake words | Betterr | 2026-10-13 | Not planned | The models are not included. |
| Per-carrier VoLTE settings | Betterr | 2026-10-13 | Open | VoLTE is switched on for every carrier with a debug property. |
| Wi-Fi country code | Betterr | 2026-10-13 | Open | wpa_supplicant is built without a driver command library, so the framework cannot hand the driver a country code. On the test unit the driver uses China's channel list. |
| Wi-Fi SAR power reduction | Betterr | 2026-10-13 | Open | Not active. On stock the trigger is not in the vendor image. |
| SAR and front colour sensors | Betterr | 2026-10-13 | Not planned | Present, unused. |
| MPEG-4 and H.263 hardware encoding | Betterr | 2026-10-13 | Open | Not ported. |
| Closed hotspot connections stay tracked for up to five days | Betterr | 2026-10-13 | Not planned | A behaviour of AOSP's tethering offload, with no measurable cost. |
| ADB in recovery is not pre-authorised | Betterr | 2026-10-13 | Not planned |  |
| Key attestation with device IDs | Betterr | 2026-10-13 | Not possible | Fails with `CANNOT_ATTEST_IDS`. Ordinary attestation works. |
