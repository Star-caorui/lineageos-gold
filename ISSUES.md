# Issues

Every known issue and request on LineageOS 24.0 for gold, in one place: the ones reported in Telegram, and the ones found while working on the trees, under Betterr. Newest first.

Status: Merged (fixed in a release), Fixing, Open (confirmed, not started), Upstream review (patch sent upstream, not in our builds), Need info, Not tested, Not planned, Not a bug, Not possible.

| Issue | Reporter | Date | Status | Notes |
| --- | --- | --- | --- | --- |
| The setup wizard's language list stutters when scrolled | Betterr | 2026-10-23 | Open | Frames take 100–280 ms on the big cores at 2.4 GHz. Each list row asks setupcompat's `PartnerConfigHelper` for Google's partner provider (`com.google.android.setupwizard.partner`); without it the failed lookup is not cached, so a scroll makes hundreds of `getContentProvider` binder calls per frame (9,453 in 30 s, 16,300 error log lines). Upstream: still so on `lineage-24.0` of LineageOS/android_external_setupcompat (`15f79d6`). A setupcompat patch that remembers the provider is missing, tried on the test unit with the same 12 flings: 2,528 failed lookups to 0, 99th-percentile frame 77 ms to 19 ms. On `lineage-24.0` of [android_external_setupcompat](https://github.com/Star-caorui/android_external_setupcompat); not in our builds, not sent to Gerrit yet. |
| Recording on the 2 MP depth camera fails at 1080p and above | Betterr | 2026-10-23 | Fixing | On units without an ultrawide, the camcorder profiles offered 1080p, 2560x1440 and 120 fps on camera 2, which streams at most 1600x1200 and has no high-speed mode. Only apps that open camera 2 directly can reach it; Aperture hides it. Up to 720p on `camera-sku` of [android_device_xiaomi_gold](https://github.com/Star-caorui/android_device_xiaomi_gold); not yet tried on the test unit. |
| Compatibility with fenrir-patched LK | Betterr | 2026-10-23 | Fixing | Mashopy's two Nothing-2A patches ported to the `lineage-24.0-fenrir` branches of our `android_system_core` and `android_system_fs_fs_mgr` forks. Selected by the build manifest; not yet build- or device-tested. See [local_manifests](https://github.com/Star-caorui/local_manifests) for the lock-check changes and their implications. |
| The ST STICK battery chip's pairing signature is checked on half its bytes | Betterr | 2026-10-19 | Fixing | Stock's driver copies only r of the signature, not s. The whole signature is copied on `lineage-24.0` of [android_kernel_xiaomi_gold-huaqin_modules](https://github.com/Star-caorui/android_kernel_xiaomi_gold-huaqin_modules). Only units with that chip; the test unit has an SLG chip, which still authenticates with the change. |
| The battery's authentication chip gets the cycle count written into it | Betterr | 2026-10-19 | Not a bug | The chip is where the battery keeps its cycle count: auth_battery adds what the gauge counted since the last update, as stock does, and the battery power supply reports the count from the chip. Leaving the chip alone left the count at 0. |
| Reading the DS28E30 battery chip's pages crashes the kernel | Betterr | 2026-10-19 | Fixing | ds_pagedata and ds_cycle_count read a 32-byte page into 16-byte buffers, as stock's driver does, and the kernel's fortify check turns that into an oops. 32-byte buffers and a read-only ds_pagedata on `lineage-24.0` of [android_kernel_xiaomi_gold-huaqin_modules](https://github.com/Star-caorui/android_kernel_xiaomi_gold-huaqin_modules). Only units with that chip; the test unit has an SLG chip, so only reading the nodes without the chip is tested. |
| The stock battery driver reports a cycle count in the thousands | Betterr | 2026-10-17 | Open | 1668 on the test unit and 4519 on ukriu's. The driver is now built from source the way stock builds it, and reports the same. Shown as is in the device diagnostics. |
| Camera crashes when switching to the macro lens while recording | ukriu | 2026-10-17 | Fixing | The camcorder profiles offered 1080p on camera 3, the 2 MP macro on units with an ultrawide, and the camera HAL refuses that stream. Camera IDs differ by layout: without an ultrawide, camera 2 is the 2 MP depth sensor and 3 the logical camera. gold_in and iron_gl now pick their own profiles, without 1080p and QHD on the macro, on `camera-sku` of [android_device_xiaomi_gold](https://github.com/Star-caorui/android_device_xiaomi_gold). Not testable on the test unit. |
| Multitasking lags below 30 % battery | yuuki | 2026-10-17 | Open |  |
| UI lags right after leaving a game | yuuki | 2026-10-17 | Open |  |
| Move the init_boot ramdisk from vendor_boot to boot | ukriu | 2026-10-17 | Not possible |  |
| extract-kernel.sh deletes the whole gold-kernel checkout | Betterr | 2026-10-16 | Merged (2026101701) | It removed its output directory first, by default the gold-kernel checkout with its history, README, `gki/` and GKI symbol versions. |
| Health HAL judges the charge counter's unit against two different capacities | Betterr | 2026-10-16 | Merged (2026101701) | One path used the design capacity, the other the capacity the battery reports. |
| Audio parameter parser keeps running unregistered when it fails to register | Betterr | 2026-10-16 | Merged (2026101701) |  |
| Stock init scripts make some device nodes and camera files world-writable | Betterr | 2026-10-16 | Open | 0666 and 0777 copied from stock; SELinux still limits access. Tightening them needs each feature tried on a phone. |
| Offline charging screen polls the panel state every 200 ms | Betterr | 2026-10-16 | Fixing | It did so to restore the backlight, which the panel lost every time the display was enabled again. The vendor modules now send the backlight level again whenever the display comes back (`lineage-24.0` of [android_kernel_xiaomi_gold-modules](https://github.com/Star-caorui/android_kernel_xiaomi_gold-modules)) and the device tree no longer polls. On the test unit the charger screen comes back lit on a key press. |
| Settings > System > Diagnostic screen is broken | ukriu | 2026-10-16 | Merged (2026101701) | It showed the battery at 0 % of its original capacity and 0 % of the storage's lifetime left. The health service now derives the battery's state of health from its full charges (99 % on the test unit), and vold reads the UFS health descriptor (70 % left). |
| Bluetooth call uses the phone's microphone instead of the earbuds' | ukriu | 2026-10-16 | Need info |  |
| Release notes: list the commits since the previous release | ukriu | 2026-10-16 | Open |  |
| Bluetooth audio goes silent after a game plays a sound | ukriu | 2026-10-15 | Merged (2026101701) | Android 17 switches the codec configuration for game sound and reopens the audio session each time; stock's audio HAL leaves its Bluetooth port disabled. An 18-line patch to the Bluetooth module (Gerrit 508408), carried in our builds from a fork until it is merged. Tested on the test unit with AAC earbuds: no session restart. |
| LDAC goes silent after a few seconds | ukriu | 2026-10-15 | Merged (2026101701) | Likely the same cause as the game sound one; its patch is in this release. Not retested. |
| Call audio does not go to Bluetooth earbuds | ukriu | 2026-10-15 | Merged (2026101701) | Likely the same cause as the game sound one; its patch is in this release. Not retested. |
| LDAC limited to 16 bits per sample | ukriu | 2026-10-15 | Need info |  |
| 5G (NSA) never shows, stuck on LTE | affan | 2026-10-15 | Merged (2026101701) | MediaTek's RIL offers NR only with EN-DC on, and the modem had it off for that SIM. Turning EN-DC on with `setNrDualConnectivityState` brought 5G up and survived a reboot. A small system app now turns it on at boot and when the carrier configuration changes. Not tested on our unit, which has no SIM. |
| No Files app | affan | 2026-10-15 | Not a bug | The system's Files app (DocumentsUI) is in the app list. |
| NFC turns on but does not read anything | affan | 2026-10-15 | Need info |  |
| Rear cameras fail after a dirty flash | affan | 2026-10-15 | Not a bug |  |
| Dolby Atmos | Thakur | 2026-10-15 | Not planned | Stock's effect libraries (Dolby, MiSound, spatial audio) are not included. |
| User build to pass Play Integrity | Thakur | 2026-10-15 | Not planned |  |
| Sunlight mode | yuuki | 2026-10-15 | Not possible | The panel has one brightness range, and its upper half is the high brightness mode that auto-brightness already uses. |
| Fast charging settles at 8–10 W | ukriu | 2026-10-14 | Open | With the screen on, Xiaomi's thermal daemon raises the charging thermal level. Stock switches it between scene profiles; nothing does here, so it stays on the default one. With the daemon stopped it held about 20 W. |
| 24 fps video stays at 60 Hz instead of 120 Hz | ukriu | 2026-10-14 | Need info | A 24 fps video in Glimpse played at 120 Hz on the test unit, with `debug.sf.frame_rate_multiple_threshold=120` and without it. Which player, and how was 60 Hz seen? |
| Status bar updates push the refresh rate back to 120 Hz | ukriu | 2026-10-14 | Not planned |  |
| Charger-connected vibration is too long | ukriu | 2026-10-14 | Not a bug |  |
| Vibration intensity slider | ukriu | 2026-10-14 | Not planned |  |
| Burn-in protection | ukriu | 2026-10-14 | Not a bug | AOSP's burn-in protection (`config_enableBurnInProtection`) has been on in every release, as on LineageOS's other OLED devices. |
| Freeform windows | ukriu | 2026-10-14 | Not planned |  |
| Writes to the other slot after an OTA are lost on reboot | ukriu | 2026-10-14 | Not planned |  |
| Offline charging loops on the Redmi logo when an alarm is set | Betterr | 2026-10-14 | Open | Seen on the test unit only. On 2026-10-19 the loop did not come back with an alarm set, but entering offline charging took one or two restarts more than the usual one. Cause not found; the reset leaves no crash record. |
| WCDMA does not work | ukriu | 2026-10-14 | Not a bug |  |
| Flashlight cannot be turned off from the control center | Niko | 2026-10-14 | Need info |  |
| Jitter when opening an app a second time | yuuki | 2026-10-14 | Merged (2026101403) |  |
| Volume keys do not change call volume | yuuki | 2026-10-14 | Merged (2026101401) |  |
| QR scanner tile stuck on "updating" | yuuki | 2026-10-14 | Not a bug |  |
| Game space | yuuki | 2026-10-14 | Not planned |  |
| Leica / HyperOS camera modules show a black preview | Asnalstan, yuuki | 2026-10-14 | Not planned | The app looks up a constructor of `StreamConfigurationMap` that only Android 14 had. Adding it back takes two patches to `frameworks/base`, as crDroid, Lunaris and AxionOS carry; we do not. |
| Flashlight strength control | Thakur | 2026-10-14 | Not planned |  |
| Fast charging on units with the LN8000 charge pump | Betterr | 2026-10-14 | Not tested | Tested on a unit with the SC8551 only. |
| Video calls | Betterr | 2026-10-14 | Not tested |  |
| Game-mode touch tuning | Betterr | 2026-10-14 | Not planned | Driven by Xiaomi's `touchfeature` service, which is not included. |
| DC dimming and colour modes | Betterr | 2026-10-14 | Open | Stock's come from Xiaomi's `displayfeature` service. Here they would need a small LiveDisplay service writing panel nodes under `/sys/class/mi_display/disp-DSI-0/`; nobody has tried what writing them does. |
| Lock screen does not say when the charger is a fast one | Betterr | 2026-10-13 | Fixing | No power supply reported the charger's current_max and voltage_max, which Android uses to tell a fast charger. Reported on the usb power supply on `lineage-24.0` of [android_kernel_xiaomi_gold-modules](https://github.com/Star-caorui/android_kernel_xiaomi_gold-modules); on the test unit's charger the lock screen says "Charging rapidly". |
| Backuptool post-install step fails on every update (harmless) | Betterr | 2026-10-13 | Not a bug | update_engine reads an ext4 mount count on vendor, which is EROFS, then looks for add-on scripts there and logs `ret=32512`. Carrying real add-ons over an update has not been tried. |
| Two SELinux denials logged now and then: the positioning daemon reading a property, the media provider at the root directory | Betterr | 2026-10-13 | Open | No effect seen. Not traced. |
| Decoding several DNG files at once can crash the app (a race in AOSP's DNG library) | Betterr | 2026-10-13 | Not planned | About once in twenty tries with four threads. Not patched. |
| Screen lock cannot be set after setup (FRP) | ukriu | 2026-10-13 | Merged (2026101303) | Factory reset protection is left off: a build without Google apps cannot clear what a Google-equipped system left on the FRP partition. With the bootloader unlocked, `fastboot erase frp` removes it. |
| KernelSU finds no ramdisk to patch | ukriu | 2026-10-13 | Merged (2026101303) |  |
| No touch in recovery | ukriu | 2026-10-13 | Merged (2026101303) |  |
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
| Always-on display keeps the system awake (about 290 mA) | Betterr | 2026-10-13 | Open | The panel runs in video mode. Tried: command mode in doze keeps the frame in panel RAM, but TE does not come back through the MT6382 bridge and leaving doze does not restore video mode. |
| Offline charging screen wakes with the power key only | Betterr | 2026-10-13 | Not a bug | As in AOSP. |
| ADB in recovery is not pre-authorised | Betterr | 2026-10-13 | Not planned |  |
| Status bar overflow dot spacing and landscape cutout insets | Betterr | 2026-10-13 | Not a bug | Stock Android behaviour. |
| Hotspot on another band than Wi-Fi | Betterr | 2026-10-13 | Not possible | There is a single Wi-Fi radio: while on 5 GHz Wi-Fi the hotspot can only use the same channel. |
| Wi-Fi 6 | Betterr | 2026-10-13 | Not possible | The chip reports no HE capability; the link tops out at 433 Mbps. |
| Hotspot hardware offload | Betterr | 2026-10-13 | Not possible | The modem's offload driver reports itself disabled. |
| Key attestation with device IDs | Betterr | 2026-10-13 | Not possible | Fails with `CANNOT_ATTEST_IDS`. Ordinary attestation works. |
