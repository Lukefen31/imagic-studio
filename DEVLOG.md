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

## 2026-11-23 — 1.0.2: own identity, side-by-side installer

A Windows 10 customer reported that studio "does nothing" when started.
Root cause: studio still identified as stock Krita 5. It used the same
single-instance key ("Krita5" + home), application name and config files,
so any running krita.exe swallowed the launch. The inherited NSIS logic
also treated an installed Krita as an older studio and uninstalled it.

Commit f95e423 (board #2137):
- app name "imagic-studio" and key "imagicstudio1"; data in
  %APPDATA%\imagic-studio, %LOCALAPPDATA%\imagic-studiorc/displayrc, and
  imagic-studio.log. Krita's files are never read or migrated.
- relaunching while studio runs raises the existing window.
- installer: imagicStudio_x64 uninstall key, Software\imagic studio, own
  ProgID imagicStudio.Image. No Krita detection or removal, no shell
  extension. Upgrades remove only a Krita_x64 entry named "imagic studio".

Tested on Win11 with silent install, a fake stock-Krita registry install,
and v1.0.0 running as a Krita5-key process. Studio opened its own window
and the data landed in the new locations. Relaunching handed off to the
running studio and focused it. After uninstall, the Krita keys were
byte-identical to before.

Known: during the first ~80 s startup (resource DB build), a second launch
still opens a second instance. That is upstream behaviour, because the
busy instance cannot answer within the 5 s handoff timeout.
