# Mobile console

The mobile console is a high-level controller around Tauri v2 plus Android SDK/Xcode tooling.

## Android workflow

Recommended local flow:

```text
Environment profile (local/LAN)
  -> Android doctor
  -> initialize target if needed
  -> adb reverse or LAN API configuration
  -> tauri android dev
  -> logcat / screenshot / deep-link tools
```

Recommended release flow:

```text
quality gate
  -> Git state check
  -> release APK/AAB
  -> signing verification
  -> SHA-256/release report
  -> install smoke test on a physical device
```

AAB generation uses Tauri's Android build `--aab` mode. APK generation/signing remains available for testing and direct distribution.

## Network testing

A physical phone cannot use the host's `localhost` to reach a backend on the computer. Use either:

- a LAN profile with the computer's LAN IP, or
- USB `adb reverse tcp:3000 tcp:3000`.

## iOS

iOS tools are enabled only on macOS. They use Tauri iOS commands and Xcode/simulator tooling. Code-signing and App Store provisioning still belong to Xcode/Apple tooling and are intentionally not faked on non-macOS systems.
