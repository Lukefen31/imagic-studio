# imagic studio — DEVLOG

## 2026-08-19 — Milestone 1: fork, rebrand, first green Windows build

Repo created as a GitHub fork of KDE/krita. Branch model: `master` mirrors
upstream, `imagic/main` carries the patch series (see README-IMAGIC.md for
the discipline rules). Five commits landed:

- display-name rebrand (KAboutData displayName only; every internal
  "krita" identifier deliberately kept — config paths, exe name, bundle
  id, translation domain are load-bearing)
- Photoshop-compatible shortcut scheme + canvas input profile as
  first-run defaults
- updater compiled out, KDE Matomo tag emptied, dev-fund banner replaced
  with an honest "based on Krita, support fund.krita.org" credit
- imagic icon set / logo svgz / 4K splash generated from imagic brand
  assets
- GitHub Actions Windows build mirroring upstream's GitLab contract
  (public prebuilt deps from invent.kde.org, llvm-mingw, pinned CMake
  3.31.8, upstream's own run-ci-build.py + packaging scripts)

First build: green on the first attempt, 1h29m on the free 4-core
runner (run 32203374133). Artifacts: portable zip, NSIS setup.exe,
unsigned MSIX (570 MB total). Launched locally: main window titles
"imagic studio", imagic splash and taskbar icon, PS shortcuts active,
VERSIONINFO reads "imagic studio digital painting application".

Next: in-app message-box titles still say "Krita" (cosmetic sweep),
installer/NSIS + artifact naming rebrand, custom Photoshop-layout
default workspace (author in-app, ship as resource), macOS build,
imagic.ink/studio product page. Wordmark lockup says "imagic" only —
"imagic studio" lockup is a design task (wordmark font unrecorded).
