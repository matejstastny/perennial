# Perennial

A procedurally generated top-down world built with Godot 4.6 and pure GDScript.

## Getting Started

**Prerequisites:** [Godot 4.6](https://godotengine.org/download/) and Python 3 (for web deploy).

### Run locally

1. Open Godot, click **Import**, select this folder
2. Press **F5** (or the Play button)

That's it — no compilation, no toolchain.

### Deploy to web

```bash
python tools/deploy.py
```

Opens the game at `http://localhost:8060`. Auto-detects Godot on macOS and Windows. Override with:

```bash
# macOS / Linux
GODOT=/path/to/Godot python tools/deploy.py

# Windows
set GODOT=C:\path\to\Godot.exe && python tools\deploy.py
```

> The web export preset is already configured. You only need to download web export templates once: **Editor → Manage Export Templates → Download**.

## Project Structure

```
scenes/
  game.tscn             # Main scene — entry point
scripts/
  game_world.gd         # Orchestrates world gen, player spawn, camera
  world_generator.gd    # Procedural terrain via two FastNoiseLite layers
  tile_map_manager.gd   # TileMapLayer: renders tiles, walkability queries
  tile_registry.gd      # Tile metadata: walkable, speed modifier, color
  player.gd             # CharacterBody2D with terrain-aware movement
assets/
  sprout_lands/         # Sprout Lands sprite pack (characters, objects, tilesets)
ui/                     # UI scenes and scripts
tools/
  deploy.py             # Export to web and serve locally
```

## How It Works

World generation uses two Simplex noise layers (elevation + moisture) to classify each tile:

| Tile   | Condition                          | Speed   |
|--------|------------------------------------|---------|
| Water  | elevation < −0.25                  | blocked |
| Sand   | elevation < −0.05                  | 80%     |
| Forest | elevation < 0.40, moisture high    | 65%     |
| Dirt   | elevation < 0.40, moisture low     | 85%     |
| Grass  | elevation < 0.40                   | 100%    |
| Stone  | elevation ≥ 0.40                   | 100%    |

## Extending the Game

**Add a tile type:** add a value to the `TileType` enum and a row to `_DATA` in `tile_registry.gd`, then add a biome condition in `world_generator.gd`.

**Change world size or seed:** set `world_width`, `world_height`, `world_seed` on the `GameWorld` node in `scenes/game.tscn`.

**Replace placeholder visuals:** drop sprite sheets into `assets/` and update `_build_tileset()` in `tile_map_manager.gd` to use real atlas sources instead of the generated solid-color textures.

**Add a new scene:** create it under `scenes/`, attach a script from `scripts/`, and instantiate it from `game_world.gd` or the scene tree.

# Assets:

- [itch.io game assets free tag pixel art](https://itch.io/game-assets/free/tag-pixel-art)
- [Sprout Lands Asset Pack](https://cupnooble.itch.io/sprout-lands-asset-pack)
- [Sprout Lands UI Pack](https://cupnooble.itch.io/sprout-lands-ui-pack)
- [Pixel Planet Generator](https://deep-fold.itch.io/pixel-planet-generator)
- [Basic Pixel Health Bar and Scroll Bar](https://bdragon1727.itch.io/basic-pixel-health-bar-and-scroll-bar)
