# \# Asset Browser

# 

# > \*\*Create beautiful game environments directly inside Godot.\*\*

# >

# > Asset Browser combines a powerful asset browser with a professional environment painting system. Browse your `.tscn` assets, paint them directly onto surfaces, generate forests, scatter props, create paths, and build entire environments without leaving the editor.

# 

# !\[Asset Browser](screenshots/preview.png)

# 

# \---

# 

# \# Features

# 

# \## 📁 Asset Browser

# 

# \- Browse any folder of `.tscn` assets

# \- Thumbnail previews

# \- Live search

# \- Favorites

# \- Recently used assets

# \- Custom asset collections

# \- Asset tags

# \- Adjustable thumbnail sizes

# \- Drag-and-drop placement into 2D and 3D

# \- Persistent browser settings

# 

# \---

# 

# \# 🌿 Environment Painter

# 

# Paint assets directly onto meshes in the 3D editor.

# 

# Features include:

# 

# \- Paint Brush

# \- Erase Brush

# \- Reapply Brush

# \- Rectangle Scatter

# \- Lasso Scatter

# \- Fill Mesh

# \- Surface Path Brush

# 

# Supports:

# 

# \- Scene Instances

# \- MultiMesh

# \- Undo / Redo

# 

# \---

# 

# \# 🖌 Brush Controls

# 

# Quick access controls:

# 

# \- Radius

# \- Count

# \- Density

# \- Spacing

# \- Alignment

# \- Surface Offset

# \- Rotation

# \- Scale

# \- Surface Filters

# 

# Context-sensitive controls automatically appear depending on the active brush.

# 

# \---

# 

# \# 🌲 Scatter System

# 

# Multiple distribution modes:

# 

# \- Uniform Random

# \- Blue Noise

# \- Clustered

# \- Center Bias

# \- Edge Bias

# 

# Additional controls:

# 

# \- Brush Falloff

# \- Per-asset spacing

# \- Random seed

# \- Deterministic placement

# 

# \---

# 

# \# 🌳 Surface Painting

# 

# Paint directly onto:

# 

# \- MeshInstance3D

# \- Terrain

# \- Static geometry

# \- Sloped surfaces

# 

# Supports:

# 

# \- Surface alignment

# \- Keep Upright

# \- Blend alignment

# \- Custom up axis

# 

# \---

# 

# \# 🌄 Surface Filters

# 

# Filter placement using:

# 

# \- Minimum slope

# \- Maximum slope

# \- Minimum height

# \- Maximum height

# \- Layer mask

# \- Selected surface only

# 

# \---

# 

# \# 🌿 MultiMesh Support

# 

# Paint directly into MultiMeshes for extremely large environments.

# 

# Features:

# 

# \- Automatic mesh extraction

# \- Material preservation

# \- Random transforms

# \- Chunked MultiMeshes

# \- Visibility ranges

# \- Spatial hash optimization

# 

# \---

# 

# \# 🌲 Weighted Variants

# 

# Paint naturally varied environments.

# 

# Choose multiple assets and assign custom weights.

# 

# Example:

# 

# ```

# Pine Tree       60%

# 

# Oak Tree        30%

# 

# Dead Tree       10%

# ```

# 

# Each asset can have:

# 

# \- Custom weight

# \- Custom spacing

# \- Enable/disable

# \- Ecosystem category

# 

# \---

# 

# \# 🌎 Ecosystem Brushes

# 

# Create reusable ecosystem brushes.

# 

# Example:

# 

# ```

# Forest

# 

# Trees

# &#x20;   Pine

# &#x20;   Oak

# &#x20;   Dead Tree

# 

# Ground Cover

# &#x20;   Grass

# &#x20;   Flowers

# 

# Details

# &#x20;   Rocks

# &#x20;   Mushrooms

# ```

# 

# Paint an entire ecosystem with one brush.

# 

# \---

# 

# \# ✏ Surface Path Brush

# 

# Draw paths directly on terrain.

# 

# Perfect for:

# 

# \- Fence lines

# \- Tree lines

# \- Roads

# \- Bushes

# \- Street lights

# \- Rivers

# 

# Supports:

# 

# \- Single Line

# \- Double Line

# \- Corridor

# \- Rows

# 

# Generated paths remain editable and automatically regenerate their contents.

# 

# \---

# 

# \# 📐 Area Tools

# 

# Rectangle Scatter

# 

# Lasso Scatter

# 

# Fill Selected Mesh

# 

# Scatter Inside Area3D

# 

# Clear Area3D

# 

# \---

# 

# \# ♻ Reapply Brush

# 

# Modify existing painted assets without repainting.

# 

# Update only:

# 

# \- Rotation

# \- Scale

# \- Alignment

# \- Offset

# \- Asset Variant

# 

# \---

# 

# \# 💾 Brush Presets

# 

# Save every brush configuration.

# 

# Presets remember:

# 

# \- Selected assets

# \- Brush settings

# \- Filters

# \- Rotation

# \- Scale

# \- Scatter settings

# \- Ecosystem settings

# \- Surface Path settings

# 

# Export and import presets between projects.

# 

# \---

# 

# \# 📊 Statistics \& Analysis

# 

# Live statistics while painting:

# 

# \- Scene Instances

# \- MultiMeshes

# \- Unique assets

# \- Estimated draw calls

# \- Estimated triangle count

# \- Optimization rating

# 

# Analyze selected assets:

# 

# \- Mesh count

# \- Triangle count

# \- Materials

# \- Collision

# \- Scripts

# \- Animation

# \- Particles

# \- MultiMesh compatibility

# 

# \---

# 

# \# ⚡ Performance

# 

# Designed for extremely large scenes.

# 

# Features include:

# 

# \- Spatial hash placement

# \- Chunked MultiMeshes

# \- Cached scene loading

# \- Cached raycasting

# \- Optimized spacing tests

# \- Persistent editor settings

# 

# \---

# 

# \# ⌨ Hotkeys

# 

# | Shortcut | Action |

# |-----------|--------|

# | `\[` | Smaller Brush |

# | `]` | Larger Brush |

# | `Shift + \[` | Lower Density |

# | `Shift + ]` | Increase Density |

# | `Ctrl + \[` | Lower Count |

# | `Ctrl + ]` | Increase Count |

# | `Alt + \[` | Lower Spacing |

# | `Alt + ]` | Increase Spacing |

# | `Shift + Paint` | Temporary Erase |

# | `Ctrl + Paint` | Precise Placement |

# | `Esc` | Exit Painter |

# 

# \---

# 

# \# Installation

# 

# \## Godot Asset Library

# 

# 1\. Open your project.

# 2\. Open \*\*AssetLib\*\*.

# 3\. Search for \*\*Asset Browser\*\*.

# 4\. Download and install.

# 5\. Enable the plugin in:

# 

# ```

# Project → Project Settings → Plugins

# ```

# 

# \---

# 

# \## Manual Installation

# 

# 1\. Download this repository.

# 2\. Copy:

# 

# ```

# addons/asset\_browser/

# ```

# 

# into your project's:

# 

# ```

# addons/

# ```

# 

# folder.

# 

# 3\. Enable the plugin.

# 

# \---

# 

# \# Quick Start

# 

# 1\. Open the \*\*Assets\*\* dock.

# 2\. Choose an asset folder.

# 3\. Select one or more assets.

# 4\. Click \*\*Paint Assets\*\*.

# 5\. Click \*\*Use Selected Parent\*\*.

# 6\. Select a parent node.

# 7\. Paint directly onto your scene.

# 

# \---

# 

# \# Requirements

# 

# \- Godot 4.7+

# \- Windows, Linux, macOS

# 

# \---

# 

# \# Roadmap

# 

# Planned future improvements include:

# 

# \- Terrain texture mask painting

# \- Vertex color painting

# \- Biome generation

# \- Procedural forest generation

# \- Advanced scatter rules

# \- World generation tools

# 

# \---

# 

# \# License

# 

# MIT License

# 

# See \[LICENSE](LICENSE).

