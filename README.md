# Flutter Deep Link Demo

A small Android and iOS app showing how a link opens a Flutter screen with `app_links` and `go_router`. A local custom scheme works immediately after installation; verified HTTPS links require a domain you control.

**Start here:** To try the app in a simulator, use `deep-link-demo://app/promo?code=SUMMER20`. `example.com`, `TEAM_ID`, and `YOUR_SHA256_FINGERPRINT` are placeholders for the separate HTTPS setup. Verified links need a domain you control and the association files hosted on that domain. Keeping files in this repository does not publish them.

## Contents

1. [Run the demo locally](#1-run-the-demo-locally)
2. [Choose your domain and app identifiers](#2-choose-your-domain-and-app-identifiers)
3. [Connect links to Flutter routes](#3-connect-links-to-flutter-routes)
4. [Configure Android App Links](#4-configure-android-app-links)
5. [Configure iOS Universal Links](#5-configure-ios-universal-links)
6. [Host the association files](#6-host-the-association-files)
7. [Test the complete flow](#7-test-the-complete-flow)
8. [Troubleshooting](#8-troubleshooting)
9. [Reuse in another app](#9-reuse-in-another-app)

## What this demo supports

| Example URL | Destination |
| --- | --- |
| `deep-link-demo://app/` | Home, without a website |
| `deep-link-demo://app/products/42` | Product `42`, without a website |
| `deep-link-demo://app/promo?code=SUMMER20` | Promotion, without a website |
| `https://example.com/` | Home |
| `https://example.com/products/42` | Product screen showing ID `42` |
| `https://example.com/profile` | Profile placeholder widget |
| `https://example.com/promo?code=SUMMER20` | Promotion screen showing `SUMMER20` |
| `https://example.com/promo` | Promotion screen showing `No promo` |

This example accepts HTTPS on the exact configured host and default port, or the exact `deep-link-demo://app` scheme and host. It preserves query parameters and ignores fragments. Unsupported links leave the current screen unchanged. Product IDs must be one nonblank path segment. Static paths are exact: `/profile/` is different from `/profile`.

The scope is URL delivery and routing. There is no login, authorization, backend lookup, or deferred deep linking after installation. The profile screen deliberately remains a placeholder. A valid link does not grant access to private data; add authorization in a real app.

## 1. Run the demo locally

Use Flutter with Dart **3.11.1 or newer within Dart 3.x**, matching `pubspec.yaml`. This project was checked with Flutter **3.41.4 / Dart 3.11.1**. The lockfile currently resolves `app_links 7.0.0` and `go_router 17.5.0`.

Install the Android SDK for Android. For iOS, use macOS with Xcode and CocoaPods; physical-device Universal Links also need an Apple Developer team with the Associated Domains capability.

From the project root:

```bash
flutter doctor
flutter pub get
flutter devices
flutter run -d <device-id>
```

After the rebuilt app is installed, run the platform test script. Each opens the promo link by default; pass another URL to test a different route:

```bash
./scripts/test_ios.sh
./scripts/test_ios.sh 'deep-link-demo://app/products/42'

./scripts/test_android.sh
./scripts/test_android.sh 'deep-link-demo://app/products/42'
```

The promo screen should show `SUMMER20`; the product screen should show ID `42`. Use `./scripts/test_ios.sh --help` or `./scripts/test_android.sh --help` for URL, device, and app-ID options. Quote URLs containing `&` or `?`. Rebuild and reinstall after changing `AndroidManifest.xml` or `Info.plist`; hot reload does not register a new URL scheme. The scheme tests link delivery and routing without domain verification. Custom schemes can be claimed by other apps, so use verified HTTPS links for trusted production links.

Run the automated checks:

```bash
flutter analyze
flutter test
```

Tests cover URL validation and routing through an injected link stream. They do not verify your website, signing identity, or OS link delivery.

## 2. Choose your domain and app identifiers

Use the same host everywhere. `example.com`, `www.example.com`, and a hosting provider's subdomain are separate hosts.

| Value | Demo value | Where to configure it |
| --- | --- | --- |
| HTTPS host | `example.com` | `deepLinkHost` in `lib/routing/deep_link_service.dart`; Android intent filter; iOS entitlements; hosted URLs |
| Local URL scheme and host | `deep-link-demo://app` | `demoLinkScheme`/`demoLinkHost` in Dart; Android intent filter; iOS URL Types |
| Android application ID | `com.example.deep_link_demo_app` | `applicationId` in `android/app/build.gradle.kts`; `package_name` in `assetlinks.json` |
| Android signing certificate | `YOUR_SHA256_FINGERPRINT` | `sha256_cert_fingerprints` in `assetlinks.json` |
| iOS bundle ID | `com.example.deepLinkDemoApp` | Runner target's Bundle Identifier in Xcode; `appIDs` in the Apple association file |
| Apple app identifier prefix | `TEAM_ID` | Prefix in the Apple association file; normally your Apple Team ID |

Select **your own signing team** in Xcode; the project currently contains the original developer's team selection. For older Apple accounts, the App ID prefix can differ from the Team ID. Match the signed app's `application-identifier` entitlement exactly.

When adapting an existing Android app, use its installed variant's `applicationId`, including any flavor suffix. The Kotlin namespace alone is not the association identity.

## 3. Connect links to Flutter routes

```text
HTTPS or custom-scheme link → Android/iOS → app_links → DeepLinkService → GoRouter → screen
```

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Initialize Flutter and subscribe before `runApp` |
| `lib/routing/deep_link_service.dart` | Check the URL and pass an internal location to the router |
| `lib/routing/app_router.dart` | Define the supported routes |
| `lib/app/app.dart` | Attach the router to `MaterialApp.router` |
| `lib/features/` | Render the destination screens |

For another Flutter app, add the dependencies:

```bash
flutter pub add app_links go_router
```

Check the selected versions' Flutter/Dart requirements. Copy/adapt the service and route definitions, then initialize them as this demo does:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deepLinkService = DeepLinkService(router);
  await deepLinkService.initialize();
  runApp(const MyApp());
}
```

`MyApp` uses `MaterialApp.router(routerConfig: router)`. The service subscribes to `AppLinks().uriLinkStream`, which includes the initial link and subsequent links. Adding a second navigation call through `getInitialLink()` can process startup twice. See the [app_links usage guide](https://pub.dev/packages/app_links/versions/7.0.0).

The service lives for the app process in this demo. If you put it in a shorter-lived owner, call `dispose()` when that owner is destroyed. The optional `linkStream` argument is for tests.

For `/products/:id`, read `state.pathParameters['id']`. For `/promo?code=SUMMER20`, read `state.uri.queryParameters['code']`. The service uses `router.go()`, so each link replaces the current route stack; it does not add a Home screen beneath the destination.

## 4. Configure Android App Links

### Register the HTTPS host

In `android/app/src/main/AndroidManifest.xml`, put these entries **inside the existing `.MainActivity` activity**. Keep its launcher intent filter and `android:exported="true"`.

```xml
<meta-data
    android:name="flutter_deeplinking_enabled"
    android:value="false" />

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="example.com" />
</intent-filter>
```

Replace the host. `false` lets `app_links` own delivery; Flutter's built-in handler must be disabled when using this plugin. See [Flutter's Android setup](https://docs.flutter.dev/cookbook/navigation/set-up-app-links).

The HTTPS filter accepts HTTPS links for its configured host. The Dart service restricts the routes. An unsupported path may launch the app but is ignored after delivery. If other website pages must stay in the browser, narrow the manifest filter with `android:path` / `android:pathPrefix`, and keep those paths aligned with your routes. See [Android intent filters](https://developer.android.com/training/app-links/add-applinks).

For local testing, the demo also registers a **separate** nonverified intent filter inside `.MainActivity`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="deep-link-demo" android:host="app" />
</intent-filter>
```

Keep this separate from the `android:autoVerify="true"` HTTPS filter. Update the scheme and host together with Dart if you rename them.

### Get the correct SHA-256 certificate fingerprint

From the project root, generate the signing report:

```bash
(cd android && ./gradlew signingReport)
```

Use the **SHA-256** value for the certificate signing the app installed on your device. For the standard local debug keystore, you can also use:

```bash
keytool -list -v \
  -keystore "$HOME/.android/debug.keystore" \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

The debug keystore exists after an Android debug build. For a local release keystore, use `keytool -list -v -keystore /path/to/release.jks -alias your-alias` and enter its password when prompted. For a Play-distributed build, use the **app signing certificate** from Play Console's App integrity page, not the upload certificate.

**Release setup still required:** `android/app/build.gradle.kts` currently signs release builds with the debug key. Configure a real release signing configuration before publishing. Prefer a development domain for debug certificates; publish only intended production certificates on your production domain.

### Prepare `assetlinks.json`

Edit `.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.deep_link_demo_app",
      "sha256_cert_fingerprints": ["YOUR_SHA256_FINGERPRINT"]
    }
  }
]
```

Replace the application ID and fingerprint. Multiple certificates for the same application ID can be listed in the array; different application IDs need separate statements. Use colon-separated SHA-256 values from the signing report. See [Android website associations](https://developer.android.com/training/app-links/configure-assetlinks).

## 5. Configure iOS Universal Links

### Disable Flutter's built-in link handler

In `ios/Runner/Info.plist`, inside the top-level `<dict>`:

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

This flag is already set in the demo. It prevents competing handlers when using `app_links`. See the [plugin's iOS instructions](https://github.com/llfbandit/app_links/blob/main/doc/README_ios.md).

For the local scheme, `Info.plist` also registers `deep-link-demo` under `CFBundleURLTypes` / `CFBundleURLSchemes`. It does not require Associated Domains. If you change the scheme, update `Info.plist` and `demoLinkScheme` in Dart together, then rebuild the app.

### Enable Associated Domains

Open the workspace after fetching packages:

```bash
flutter pub get
(cd ios && pod install)
open ios/Runner.xcworkspace
```

In Xcode, select **Runner project → Runner target → Signing & Capabilities**:

1. Select your signing team and confirm the Bundle Identifier.
2. Add **Associated Domains** if it is not already present.
3. Add `applinks:example.com`, replacing the host. Do not include `https://` or a path.
4. Ensure the App ID and provisioning profile support Associated Domains. Personal development teams do not support this capability.

The demo's `ios/Runner/Runner.entitlements` contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:example.com</string>
    </array>
</dict>
</plist>
```

Under **Build Settings → Code Signing Entitlements**, verify `Runner/Runner.entitlements` for **Debug, Profile, and Release**. All three are connected in this project. Rebuild/reinstall after native configuration changes; hot reload is insufficient. See [Flutter's iOS setup](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links).

### Prepare `apple-app-site-association`

Edit `.well-known/apple-app-site-association`. Keep the filename **without `.json`**:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAM_ID.com.example.deepLinkDemoApp"],
        "components": [
          { "/": "/" },
          { "/": "/products/*" },
          { "/": "/profile" },
          { "/": "/promo" }
        ]
      }
    ]
  }
}
```

Replace `TEAM_ID` with your app identifier prefix and match the bundle ID exactly, including capitalization. These components select URL paths; `/promo` also allows its `code` query parameter. `/products/*` is broader than the single-ID Flutter route, so Dart validation still matters. See [Apple's associated domains guide](https://developer.apple.com/documentation/xcode/supporting-associated-domains).

This project's `AppDelegate` registers plugins with Flutter's implicit engine, and `SceneDelegate` extends `FlutterSceneDelegate`. The installed `app_links 7.0.0` supports scene callbacks. Avoid adding duplicate manual forwarding code unless your app's custom native lifecycle requires it.

## 6. Host the association files

Deploy both files to the **same host configured in the app**:

```text
https://YOUR_DOMAIN/.well-known/assetlinks.json
https://YOUR_DOMAIN/.well-known/apple-app-site-association
```

Serve them publicly over valid HTTPS with status **200** and `Content-Type: application/json`. No login, redirect, or HTML fallback should intercept either path. Some static hosts need explicit configuration to include dot directories and serve the extensionless Apple file as JSON. Check your hosting output, not just the source folder.

```bash
curl -i https://YOUR_DOMAIN/.well-known/assetlinks.json
curl -i https://YOUR_DOMAIN/.well-known/apple-app-site-association
```

Inspect both headers and JSON bodies. Do not add `-L` during this check: it would hide a redirect. Follow [Android's publishing requirements](https://developer.android.com/training/app-links/configure-assetlinks) and [Apple's association requirements](https://developer.apple.com/documentation/xcode/supporting-associated-domains).

Provide useful web pages at your product/promo URLs too. When the app is absent, the HTTPS link normally opens the website; this demo does not automatically send users to an app store or recover a link after installation.

## 7. Test the complete flow

Replace `YOUR_DOMAIN` and the application ID in these commands. Install the app after changing native settings, and give the test device internet access.

### Android: test routing separately from verification

To target the installed demo explicitly:

```bash
./scripts/test_android.sh 'https://YOUR_DOMAIN/products/42'
./scripts/test_android.sh 'https://YOUR_DOMAIN/promo?code=SUMMER20'
```

A successful package-targeted launch checks intent delivery and Flutter routing. It does **not** prove the website association is verified.

On Android 12 or newer, reset verification state on your test device, request verification, then inspect it:

```bash
adb shell pm set-app-links --package com.example.deep_link_demo_app 0 all
adb shell pm verify-app-links --re-verify com.example.deep_link_demo_app
# Wait a few minutes for verification, then:
adb shell pm get-app-links com.example.deep_link_demo_app
```

Look for `YOUR_DOMAIN: verified`. A manually selected or force-approved domain is not evidence of successful website verification. See [Android's verification guide](https://developer.android.com/training/app-links/verify-applinks).

Then test normal OS selection without specifying the package:

```bash
adb shell 'am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://YOUR_DOMAIN/products/42"'
```

Also tap a link from another app. Confirm the expected product or promotion appears.

### iOS: test Universal Links

With a configured, installed app and a booted Simulator:

```bash
./scripts/test_ios.sh 'https://YOUR_DOMAIN/products/42'
./scripts/test_ios.sh 'https://YOUR_DOMAIN/promo?code=SUMMER20'
```

On a physical device, place the link in Notes and tap it. Use a **profile or release build** for cold-launch testing on a physical iPhone; Flutter debug builds can require launching through Flutter tooling. For example:

```bash
flutter run --profile -d <physical-ios-device-id>
```

Do not rely on typing the URL into Safari's address bar as your Universal Link test. Safari can keep same-domain navigation in the browser, and previous user choices can affect opening behavior. Apple also caches association data, so a hosting change may not appear immediately. See [Apple's Universal Link debugging guide](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links).

### Check all app states

| State | Action | Expected result |
| --- | --- | --- |
| Terminated | Close the app, then open a product link | Product `42` appears on launch |
| Background | Put the app in the background, then open a promo link | App resumes with the promo code |
| Running | Deliver another supported link | Destination changes correctly |
| Invalid input delivered to service | Unknown path, missing product ID, or untrusted host | Current screen stays unchanged |

An invalid URL that the OS does not associate with your app may stay in the browser without reaching the service. Automated tests cover rejection inside Dart independently of OS delivery.

## 8. Troubleshooting

| Symptom | Check |
| --- | --- |
| Android opens the browser | Inspect `pm get-app-links`, hosted JSON, installed application's ID/certificate, and the user's Open supported links setting. |
| Debug works; Play build fails | Use the Play app signing certificate, not your local debug or upload certificate. |
| iOS opens Safari | Check Associated Domains, signed entitlements/provisioning profile, AASA app identifier and paths, and cached association data. |
| App opens but stays on Home/current screen | Match the configured HTTPS host or `deep-link-demo://app`, plus an allowed path. `/products/` has no ID. |
| Simulator opens Safari for `https://example.com/...` | `example.com` is only a placeholder; use `deep-link-demo://app/...` locally or finish the HTTPS domain association setup. |
| Links are handled twice | Keep both Flutter default handlers disabled and use one stream subscription. |
| Native edits seem ineffective | Stop, rebuild, and reinstall; hot reload does not update native configuration. |
| Promo code is missing | Use `/promo?code=SUMMER20` and quote URLs in shell commands, especially when they contain `&`. |
| `/profile` looks unfinished | It is a placeholder widget in this demo. |

## 9. Reuse in another app

- [ ] Add compatible `app_links` and `go_router` dependencies.
- [ ] Add your routes and URL validation; initialize the link subscription early.
- [ ] Disable Flutter's default handler on both platforms.
- [ ] Set the same host in Dart, Android, and iOS.
- [ ] If using a local scheme, match its scheme and host in Dart, Android, and iOS URL Types.
- [ ] Set Android's application ID and publish its actual signing certificate fingerprint.
- [ ] Enable iOS Associated Domains and connect entitlements in every build configuration.
- [ ] Match the Apple association ID to the signed app's prefix and bundle ID.
- [ ] Publish both association files and inspect their actual HTTP responses.
- [ ] Add proper release signing and any required authentication/authorization.
- [ ] Test terminated, background, and running states on both platforms.
- [ ] When adding a route, update the router, validator, Apple path rules, and any Android path filters together.

The original `example.com` URL remains a configuration example. Replace it with a domain you control before testing Universal Links or Android App Links.
