# Assets

Brand assets for Musician + Orchestra.

## Files

| File | Size | Use |
|------|------|-----|
| `musician-logo.svg` | 512×512 | Musician primary logo |
| `musician-logo-dark.svg` | 512×512 | Musician logo on dark backgrounds |
| `orchestra-logo.svg` | 512×512 | Orchestra primary logo |
| `orchestra-logo-dark.svg` | 512×512 | Orchestra logo on dark backgrounds |
| `github-avatar.svg` | 500×500 | Combined avatar for GitHub org/user profile |
| `favicon.svg` | 32×32 | Favicon (SVG, scales to any size) |

## Setting the GitHub Avatar

1. Open `assets/github-avatar.svg` and export as PNG at 500×500 (any SVG viewer → export, or use `rsvg-convert`):
   ```sh
   rsvg-convert -w 500 -h 500 assets/github-avatar.svg -o /tmp/avatar.png
   # or with Inkscape:
   inkscape assets/github-avatar.svg --export-filename=/tmp/avatar.png -w 500 -h 500
   ```
2. Go to **GitHub → Settings → Profile** (for a user) or **GitHub → Your Organizations → {org} → Settings → Profile** (for an org).
3. Click **Change profile picture** and upload the PNG.

## Adding a Favicon to GitHub Pages

If you have a GitHub Pages site for this repo:

1. Add to the `<head>` of your HTML:
   ```html
   <link rel="icon" type="image/svg+xml" href="/assets/favicon.svg">
   ```
2. For browsers that don't support SVG favicons, generate a `favicon.ico`:
   ```sh
   rsvg-convert -w 32 -h 32 assets/favicon.svg | convert - assets/favicon.ico
   ```

## Using in Markdown

```markdown
<!-- Centered logo in README -->
<div align="center">
  <img src="assets/musician-logo.svg" width="200" alt="Musician" />
</div>

<!-- Inline logo -->
![Musician](assets/musician-logo.svg)
```

## Color Palette

| Token | Hex | Use |
|-------|-----|-----|
| Purple dark | `#1a0533` | Background |
| Purple mid | `#7c3aed` | Primary accent |
| Magenta | `#c026d3` | Highlight |
| Cyan | `#06b6d4` | Terminal / streams |
| Amber | `#f59e0b` | Orchestra / conductor |
| Pink light | `#f0abfc` | Note gradient high |
| Cyan light | `#67e8f9` | Note gradient low |
