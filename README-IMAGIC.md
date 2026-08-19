# imagic studio

A desktop image editor by [imagic](https://imagic.ink), built as a branded
fork of [Krita](https://krita.org). One-time purchase, no subscription.

This repository is the complete corresponding source for every imagic studio
binary we distribute, including the build and packaging scripts, published
here in satisfaction of GPLv3 section 6. The software is licensed under the
GNU General Public License v3 (see `COPYING`). The imagic name and brand are
not GPL-licensed; see `TRADEMARKS.md`.

## Branch model

- **`master`** mirrors upstream Krita and is never committed to directly.
  It advances only by fetching from upstream.
- **`imagic/main`** is the product branch: upstream plus a deliberately
  small patch series (branding, defaults, update channel). Releases are
  tagged from here.

## Patch discipline

The fork survives only if rebasing onto each upstream release stays cheap.
Every commit on top of upstream must therefore be:

1. **Branding or defaults only.** Application name, icons, splash,
   default workspace and shortcut scheme, update-check URL, store links.
   Feature work belongs upstream, not here.
2. **Small and self-contained.** One concern per commit, no drive-by
   refactors of upstream code.
3. **GPL-clean.** Nothing proprietary ever enters this repository. All
   commercial logic (licensing, accounts, checkout, delivery) lives
   server-side in imagic's own systems and is not part of this program.

## Upstream tracking

Fetch upstream from the KDE mirror and rebase the patch series:

    git remote add upstream https://github.com/KDE/krita.git
    git fetch upstream
    git rebase upstream/master   # on imagic/main, resolve, retest

Upstream development happens at invent.kde.org/graphics/krita; the GitHub
repo is a read-only mirror. Consider supporting the Krita Foundation
(krita.org/en/support-us/) — this product exists because of their work.

## Building

Follow upstream's build documentation for now (see `README.md` and
https://docs.krita.org/en/untranslatable_pages/building_krita.html).
imagic-specific packaging and CI will land under `packaging/imagic/` as the
patch series grows.
