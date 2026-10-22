# Phone setup

## Option A — Home Screen web app (recommended first)

1. Finish local setup and deploy the private server behind HTTPS using [DEPLOYMENT.md](DEPLOYMENT.md).
2. Open that exact HTTPS address on your phone. Sign in with your planner key; this is separate from your university login.
3. On iPhone, use Safari → Share → Add to Home Screen. On Android, use the browser's Install app option.
4. Open online once so the shell and private device state are saved. Add a harmless reminder, complete it on the phone, then Sync on the computer. Reopen it on the computer and sync back.
5. Test offline completion, reload, then reconnect. A pending queue is “saved on this device,” not “synced.” Keep both conflicting choices until you review them.

The server must be running for sync. Hosting it on a laptop means new sync stops when the laptop sleeps. A server/VPS with a persistent disk avoids that limitation for saved planner data. It still cannot inspect a sleeping laptop's signed-in Brightspace session.

Browser notifications are on-demand from Phone & setup. They are not a background scheduler. No native Android application is included.

## Option B — Native iPhone companion

Source in `ios/` preserves the original companion's useful functions: authenticated web planner, Home/Lock Screen widgets, saved schedule import, and optional silent reminders twenty minutes before schedule blocks. The server remains the same private planner.

Requirements: a Mac with Xcode and an iOS 17+ phone; your own Apple signing identity and App Group capability. Provisioning eligibility depends on your Apple account. This repo includes no signing certificate, original team ID, provisioned binary or App Store listing.

Configure a **private copy**, using your actual values:

```bash
npm run ios:configure -- --host planner.your-domain.example --timezone America/Toronto --bundle com.yourname.campus --team YOURTEAMID
```

Replace `YOURTEAMID` with your ten-character Apple team identifier. The host must be a real HTTPS hostname, without a port or path. The timezone must exactly match the server. The command creates `.local/ios/CampusCompanion.xcodeproj`; it refuses to overwrite an existing private copy. This keeps personal configuration out of public Git history.

Open that private project in Xcode:

1. Verify the app and widget targets use your team and unique bundle identifiers.
2. Register/enable the same App Group on both targets (`group.` plus your bundle ID). Match their entitlements.
3. Select your connected phone and Run. Handle Apple sign-in, provisioning, agreements or device trust yourself if required.
4. Open the companion, sign into your planner, then open **My widget** to confirm a saved schedule timestamp.
5. Add the widget from iPhone's Home Screen or Lock Screen widget picker. Enable silent reminders in My widget only if desired, and allow notification permission.

If web sign-in cannot be completed in the embedded view, use Safari → planner → Phone & setup → Save schedule for widget. Share/import the `.campusplan` file into the native companion. The file contains schedule details, not login credentials; treat it as private.

## Freshness and limits

The native app refreshes while visible and after sync. WidgetKit controls update timing. Saved work expires at local midnight; future classes can remain visible with a stale label. Phone alerts can fire with the app closed, but remote changes are reconciled only when the app next refreshes. Focus mode and OS settings can affect delivery.

Open the companion after changing the schedule and test an actual notification on the intended device. An unsigned simulator build is useful evidence of compilation, not proof of provisioning, installation, background delivery or physical widget behavior.

For a simulator compilation without signing:

```bash
xcodebuild -project ios/CampusCompanion.xcodeproj -scheme CampusCompanion \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .local/ios-build CODE_SIGNING_ALLOWED=NO build
```
