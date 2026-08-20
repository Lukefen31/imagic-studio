"""imagic studio MCP server.

Lets AI agents (Claude Code, Cursor, Claude Desktop, any MCP client) drive
imagic studio the way imagic Desktop's built-in MCP works: open files in
the app for a human, and run real headless conversions through the studio
engine, which reads and writes PSD, KRA, EXR, TIFF and roughly forty other
formats.

The headless work rides imagic studio's batch-export mode, which the app
deliberately runs in a separate process, so conversions work whether or
not the app is open. First conversion on a fresh machine is slow (the
engine builds its resource cache once); later runs are quick.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

try:  # MCP SDK 1.x
    from mcp.server.fastmcp import FastMCP
except ImportError:  # MCP SDK 2.x renamed it
    from mcp.server.mcpserver import MCPServer as FastMCP

# Export can legitimately take minutes on first run (resource cache build).
_EXPORT_TIMEOUT_S = 600

_EXPORT_FORMATS = (
    "psd kra png jpg jpeg webp tiff tif exr bmp gif ora pdf svg heif heic "
    "avif jxl tga ppm pbm pgm xpm ico csv"
).split()

mcp = FastMCP("imagic-studio")


def _candidate_paths() -> list[Path]:
    env = os.environ.get("IMAGIC_STUDIO_EXE", "").strip()
    out: list[Path] = []
    if env:
        out.append(Path(env))
    which = shutil.which("krita")
    if which:
        out.append(Path(which))
    for base in (
        os.environ.get("ProgramFiles", r"C:\Program Files"),
        os.environ.get("LOCALAPPDATA", ""),
    ):
        if base:
            out.append(Path(base) / "imagic studio" / "bin" / "krita.exe")
            out.append(Path(base) / "Krita (x64)" / "bin" / "krita.exe")
    return out


def _find_exe() -> Path:
    for p in _candidate_paths():
        if p and p.is_file():
            return p
    raise RuntimeError(
        "imagic studio was not found. Set the IMAGIC_STUDIO_EXE environment "
        "variable to the full path of krita.exe inside your imagic studio "
        "install (for example C:\\Program Files\\imagic studio\\bin\\krita.exe)."
    )


def _run_export(input_path: Path, output_path: Path) -> None:
    exe = _find_exe()
    proc = subprocess.run(
        [str(exe), str(input_path), "--export", "--export-filename", str(output_path)],
        capture_output=True,
        text=True,
        timeout=_EXPORT_TIMEOUT_S,
    )
    if not output_path.is_file():
        detail = (proc.stderr or proc.stdout or "").strip()[-500:]
        raise RuntimeError(
            f"Export produced no file (exit {proc.returncode}). {detail or 'No engine output.'}"
        )


@mcp.tool()
def studio_info() -> dict:
    """Where imagic studio is installed and what the conversion engine can write."""
    try:
        exe = str(_find_exe())
        found = True
    except RuntimeError as e:
        exe = str(e)
        found = False
    return {"found": found, "executable": exe, "export_formats": _EXPORT_FORMATS}


@mcp.tool()
def open_in_studio(path: str) -> dict:
    """Open an image in the imagic studio window for the human to work on.

    Reuses the running app when there is one, starts it otherwise."""
    p = Path(path).expanduser()
    if not p.is_file():
        return {"ok": False, "error": f"No such file: {p}"}
    exe = _find_exe()
    creationflags = subprocess.DETACHED_PROCESS if sys.platform == "win32" else 0
    subprocess.Popen([str(exe), str(p)], creationflags=creationflags, close_fds=True)
    return {"ok": True, "opened": str(p)}


@mcp.tool()
def convert_image(input_path: str, output_path: str) -> dict:
    """Convert an image through the studio engine. Format follows the output
    file's extension: PSD, KRA, PNG, JPG, WEBP, TIFF, EXR, ORA, PDF and more.

    This is a real engine conversion, so layered formats keep their layers
    where the target format supports them."""
    src = Path(input_path).expanduser()
    dst = Path(output_path).expanduser()
    if not src.is_file():
        return {"ok": False, "error": f"No such file: {src}"}
    if dst.suffix.lstrip(".").lower() not in _EXPORT_FORMATS:
        return {"ok": False, "error": f"Unsupported output format: {dst.suffix}"}
    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        _run_export(src, dst)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        return {"ok": False, "error": str(e)}
    return {"ok": True, "output": str(dst), "bytes": dst.stat().st_size}


@mcp.tool()
def batch_convert(input_paths: list[str], output_dir: str, format: str) -> dict:
    """Convert many images to one format. Returns per-file results."""
    fmt = format.lstrip(".").lower()
    if fmt not in _EXPORT_FORMATS:
        return {"ok": False, "error": f"Unsupported output format: {fmt}"}
    out_dir = Path(output_dir).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    results = []
    for raw in input_paths:
        src = Path(raw).expanduser()
        dst = out_dir / (src.stem + "." + fmt)
        if not src.is_file():
            results.append({"input": str(src), "ok": False, "error": "no such file"})
            continue
        try:
            _run_export(src, dst)
            results.append({"input": str(src), "ok": True, "output": str(dst)})
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            results.append({"input": str(src), "ok": False, "error": str(e)})
    done = sum(1 for r in results if r["ok"])
    return {"ok": done == len(results), "converted": done, "results": results}


@mcp.tool()
def image_info(path: str) -> dict:
    """Pixel dimensions, color mode and file size of an image."""
    p = Path(path).expanduser()
    if not p.is_file():
        return {"ok": False, "error": f"No such file: {p}"}
    try:
        from PIL import Image

        with Image.open(p) as img:
            return {
                "ok": True,
                "path": str(p),
                "format": img.format,
                "size": list(img.size),
                "mode": img.mode,
                "bytes": p.stat().st_size,
            }
    except Exception:
        # Formats PIL cannot read (KRA, EXR variants) still get file facts.
        return {"ok": True, "path": str(p), "format": p.suffix.lstrip("."), "bytes": p.stat().st_size}


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
