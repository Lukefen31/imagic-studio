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

## 2026-11-23 â€” 1.0.3: never start silently, safe graphics recovery

The same Windows 10 customer (22H2 19045, i5-10210U, Intel UHD 620 only,
German locale) still saw "nothing happens, no process" on 1.0.2.

Ruled out: studio has no licence or activation check (licensing is all
server-side), so the Plus to Max key upgrade cannot matter; the bundle
imports no VC++ redistributable DLL (pefile scan of every PE file); a
non-ASCII install path (C:\tmp\JÃ¶rg Test\...), German LANGUAGE and ANGLE
WARP (the no-GPU path) all start fine with 1.0.2. Windows Sandbox is not
enabled on the dev PC, so no clean-VM run.

Root cause (most likely, not reproducible without the hardware): before
any window or crash handler exists, upstream probes every OpenGL renderer
by creating real contexts, including desktop OpenGL through the Intel ICD
driver, plus a temporary QGuiApplication per probe. A crash there ends
the process silently on Windows 10, and every launch repeats it. A failed
final probe also dereferenced an empty optional (silent crash).

Fix (commits 41a77b5, 4489665, CI dafe9c5, board #2145):
- startup guard in krita/main.cc: crash filter, SIGABRT and qFatal
  handlers. During startup they relaunch studio (max 3), then show a
  dialog with error code, stage and log folder. DrMingw still writes
  imagic-studiocrash.log first (chained).
- stage marker in imagic-studiodisplayrc ([imagicStartup]); a launch
  after an unfinished start escalates a safe graphics level: 1 ANGLE
  D3D11 only, 2 ANGLE WARP, 3 WARP + QPainter canvas, with a notice.
  Choosing a renderer in Settings resets it.
- Intel-only GPU with the default renderer: probe only ANGLE D3D11 and
  never load the desktop OpenGL driver.
- app.start() failure shows a dialog instead of returning 1.
- env hooks: IMAGIC_STUDIO_SAFE_GRAPHICS=1..3, IMAGIC_STUDIO_TEST_CRASH=
  <gl_probe|app_init|window>[:level].
- CI: ccache install retries (Chocolatey 504), and a dispatch input
  uploads to a draft release because artifact downloads hit the account
  egress limit.

Tested on the CI build from a non-ASCII path with a fresh profile: normal
start; level 1 path; crash at gl_probe escalating through relaunches to
level 3 and opening; permanent crash at gl_probe, app_init and window all
ending in the error dialog (DrMingw log written); Settings reset; second
launch handing off. Not tested: the NSIS installer run itself (needs UAC
elevation; script unchanged since 1.0.2) and real Intel hardware.
