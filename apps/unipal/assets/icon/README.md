App icon sources (the UniPal Group mark, reversed, on ink). Not bundled in the app.

- `app_icon_rounded.svg` -> Windows `windows/runner/resources/app_icon.ico` (16-256 px) and Android `mipmap-*/ic_launcher.png`
- `app_icon_macos.svg` (824 px body on a 1024 canvas, Apple's grid) -> `macos/.../AppIcon.appiconset`
- `app_icon_full.svg` (full bleed, no transparency; iOS masks it) -> `ios/.../AppIcon.appiconset`

Colors come from unipal-brand `logos/symbol-group-reversed.svg`. Regenerate the PNGs/ICO from these SVGs if the mark changes.
