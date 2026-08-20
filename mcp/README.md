# imagic studio MCP server

Drive imagic studio from Claude Code, Claude Desktop, Cursor, or any MCP
client, the same way imagic Desktop's built-in MCP works.

Tools:

- `open_in_studio` opens a file in the app window (reuses a running app)
- `convert_image` / `batch_convert` run real engine conversions headlessly:
  PSD, KRA, PNG, JPG, WEBP, TIFF, EXR, ORA, PDF and ~40 formats in and out,
  layers preserved where the target format supports them
- `image_info` and `studio_info` for facts an agent needs before acting

Conversions use the studio's batch-export mode, which runs in its own
process, so they work whether or not the app is open. The first conversion
on a fresh machine is slow while the engine builds its resource cache once.

## Claude Code

```bash
claude mcp add imagic-studio -- uvx --from "git+https://github.com/Lukefen31/imagic-studio@imagic/main#subdirectory=mcp" imagic-studio-mcp
```

## Claude Desktop / any MCP client

```json
{
  "mcpServers": {
    "imagic-studio": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/Lukefen31/imagic-studio@imagic/main#subdirectory=mcp",
        "imagic-studio-mcp"
      ]
    }
  }
}
```

If imagic studio is not on your PATH, point the server at it:

```
IMAGIC_STUDIO_EXE=C:\Program Files\imagic studio\bin\krita.exe
```

Live in-document editing tools (layers, filters, text) are the next
milestone; they ride the same engine through its Python scripting API.
