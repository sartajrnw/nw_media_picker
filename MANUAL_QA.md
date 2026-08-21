# Manual QA Checklist — nw_media_picker

The **primary motivation** of this package is Android camera reliability across
OEM devices. Automated tests cannot cover real camera hardware, so this manual
checklist is part of the release process.

**No scenario below should crash the consuming application.** A failure should
surface as a recoverable UI (retry / gallery fallback / cancel) or a normalized
`MediaPickerException`.

## Android device matrix

Test on as many as possible — the OEM camera stacks are exactly what this
package exists to avoid:

- [ ] Samsung
- [ ] Xiaomi / Redmi
- [ ] Oppo
- [ ] Vivo
- [ ] Realme
- [ ] OnePlus
- [ ] Motorola
- [ ] Pixel
- [ ] Nothing

## Core camera scenarios (per device)

- [ ] Open camera
- [ ] Take a photo
- [ ] Take 10 photos sequentially (no leak / slowdown / crash)
- [ ] Rapidly open/close the camera repeatedly
- [ ] Switch front/back repeatedly
- [ ] Enable/disable flash (off → auto → on → torch)
- [ ] Pinch-to-zoom across the full range; zoom indicator updates
- [ ] Tap-to-focus; focus indicator appears and fades (~1s)
- [ ] Rotate the phone (portrait/landscape); preview never stretches
- [ ] Single-camera device: switch control is hidden

## Lifecycle scenarios (critical)

- [ ] Background the app while the camera is open, return after 5 seconds
- [ ] Background the app, return after 1 minute
- [ ] Lock/unlock the screen
- [ ] Receive a phone call while the camera is open, then return
- [ ] Switch to another app and back
- [ ] Confirm the preview re-initializes and remains usable after each

## Permissions

- [ ] Deny camera permission → recoverable UI (no crash)
- [ ] Permanently deny → "Open Settings" is shown; no repeated prompts
- [ ] Change permission from system Settings, return to app → recovers
- [ ] Gallery selection works without over-requesting permissions

## Image correctness

- [ ] Portrait capture is upright (not sideways)
- [ ] Landscape capture is correct
- [ ] Device rotated left / right → orientation correct
- [ ] Front camera output matches documented mirroring behavior
- [ ] Back camera output correct
- [ ] Large-resolution photo (12MP/48MP) processes without OOM
- [ ] Resized output respects `maxWidth`/`maxHeight` (longest side capped)
- [ ] Square crop preset produces a 1:1 image

## Edge / resource

- [ ] Low-memory conditions (developer options: limit background processes)
- [ ] Cancel the camera → returns `null`
- [ ] Open gallery from the camera's gallery shortcut
- [ ] Capture again after cancelling the gallery
- [ ] Resolution fallback: force a failure (if reproducible) → lower resolution
      is used, or a recoverable camera error is shown

## iOS QA

- [ ] Take a photo using the native camera picker
- [ ] Cancel the camera → returns `null`
- [ ] Front camera preference honored
- [ ] Back camera preference honored
- [ ] Gallery pick
- [ ] Cancel gallery
- [ ] Photo permissions (full)
- [ ] Limited photo access
- [ ] Background/foreground while picking
- [ ] Large HEIC image processes correctly (output is JPEG — see README)
- [ ] Portrait/landscape orientation correct

## Windows / desktop QA

- [ ] `capabilities().camera == false`
- [ ] `capabilities().gallery == true`
- [ ] Choosing an image works
- [ ] Calling `camera()` returns a normalized `unsupportedPlatform` failure
      (does not crash)
