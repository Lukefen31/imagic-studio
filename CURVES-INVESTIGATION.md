# Curves import: fixture stops loading

Status 2026-08-22. Branch `psd-curves`, parked. The four other adjustments
shipped separately in PR #1 and are green.

## Symptom

With a `curv` layer in the fixture, the whole PSD fails to open:
`doc->image()` is null and `doc->errorMessage()` is empty. Every other
fixture in the suite still loads (20 of 22 pass), so it is this file or
this branch, not the platform.

## What is ruled out

- **The block bytes.** The fixture's `curv` payload is correct:
  `isMap=0, version=4, count=1`, four points (0,0) (80,64) (190,192)
  (255,255), three bytes of padding, 28 total. Verified against psd-tools.
- **The extra layer.** Diffing the working 7-record fixture against the
  broken 8-record one shows they are identical except for the added
  `PS Curves` record, which has the same rect and channel layout as the
  Posterize and Threshold clones that load fine.
- **A short read.** The branch is now bounds-checked against the declared
  block size and the failure is unchanged.

## Next experiment, in order

1. Build the same 8-layer fixture with the `curv` key replaced by an
   unknown 4-char key. Krita skips unknown keys, so if that file loads,
   the trigger is specifically our `curv` handling; if it does not, the
   eighth record is implicated after all.
2. If it is our handling, the remaining suspect is the loader rather than
   the reader: `psdAdjustmentConfiguration` builds a `perchannel` config
   and calls `setProperty("nTransfers", ...)` then `curveN`. Try creating
   the adjustment layer with a default config and no properties at all.
3. Check whether `errorMessage()` is ever populated for import failures.
   An empty string may simply mean the import path does not set it, in
   which case that diagnostic is worthless here and `dbgFile` output needs
   capturing instead.

## Worth keeping regardless

The bounds-checking commit fixes a real flaw that predates this work:
`SAFE_READ_EX` throws, `PsdAdditionalLayerInfoBlock::read` catches and
returns false, and the layer section treats that as a corrupt file. So a
misread in one optional adjustment block loses the whole document. That
should be applied to the other adjustment branches too, and is a
reasonable standalone contribution.
