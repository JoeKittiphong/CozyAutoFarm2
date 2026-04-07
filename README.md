# Cozy Auto Farm 2

Cozy Auto Farm 2 is a 2D top-down Godot farming/automation game focused on workers, production chains, and management systems.

The project started as a simple farm prototype and has been refactored toward a more `data-driven`, `resource-based`, and `system-oriented` structure so it can scale more easily as new crops, animals, buildings, processors, and world resources are added.

## Screenshots

Add project screenshots to a folder such as `docs/screenshots/` and update the image paths below.

Suggested shots:

- main gameplay view
- worker houses and automation flow
- targets panel
- warehouse/resources
- production buildings

Example layout:

```md
![Main Gameplay](docs/screenshots/main-gameplay.png)
![Targets Panel](docs/screenshots/targets-panel.png)
```

## Current Focus

The game is moving toward a cozy desktop management experience where the player:

- grows crops
- raises animals
- runs production buildings
- gathers world resources
- expands the farm using coins and materials
- manages automation through worker houses and stock targets

## Main Features

### Data-Driven Content

Most game content is now defined through `.tres` resources instead of large hardcoded dictionaries.

Supported content groups include:

- items
- blueprints
- processors
- animals
- world resources

Core registry and helpers live in [systems/core/game_data.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/game_data.gd).

### Dynamic Inventory

The inventory system uses dictionaries instead of one variable per item, making it easier to add new content.

Main file:

- [systems/core/inventory_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/inventory_manager.gd)

### Generic Processor System

Processing buildings are no longer handled as one-off hardcoded systems. They are defined through processor data and handled by shared processor logic.

Examples currently in the project:

- Mill
- Bakery
- Tomato Factory
- Fish Cage
- Animal Feed Factory

Main file:

- [systems/farm/farm_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/farm_manager.gd)

### Dynamic Map Scanning

The map is scanned from the TileMap layers used in the editor instead of relying on a fixed hardcoded world size.

This includes:

- `GroundLayer`
- `WaterLayer`
- `ObstaclesLayer`
- `ResourceLayer`

Main files:

- [systems/grid/map_scanner.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/map_scanner.gd)
- [systems/grid/grid_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/grid_manager.gd)
- [scenes/world/world.tscn](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/world/world.tscn)

### Water Placement Rules

Water is treated as a separate surface type:

- workers cannot walk through water
- water buildings can only be placed on water
- land buildings can only be placed on land

### World Resources

The game supports gatherable map resources such as trees and rocks.

Workers can gather:

- wood
- stone

These resources are now part of the construction economy.

Main files:

- [systems/world/resource_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/world/resource_manager.gd)
- [systems/data/world_resource_definition.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/data/world_resource_definition.gd)

### Smart Animal Feeding

Animals can use premium feed first and fall back to their base food if needed.

The project also supports:

- animal feed points per bag
- animal product collection jobs
- feed-related production chains

Main file:

- [entities/animals/farm_animal.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities/animals/farm_animal.gd)

### Worker Houses and Domains

Workers are now split by house/domain instead of all sharing the same full job pool.

Current worker domains:

- Farm House
- Gathering House
- Factory House

This keeps behavior clearer and reduces over-complicated worker micromanagement.

### Target System

Instead of assigning every worker manually, the player can set stock goals for items.

Examples:

- keep wheat at 50
- keep eggs at 10
- keep wood at 30

When stock drops below the target, relevant jobs receive higher priority automatically. Once the target is met, workers return to their normal automatic behavior.

Main files:

- [systems/core/inventory_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/inventory_manager.gd)
- [systems/farm/job_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/job_manager.gd)
- [scenes/ui/hud.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.gd)

### Scene-Based HUD

The HUD has been refactored toward a more Godot-native scene-based UI structure.

Panels now include:

- Shop
- Warehouse
- Targets
- Worker management/status
- Upgrade panel

Main files:

- [scenes/ui/hud.tscn](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.tscn)
- [scenes/ui/hud.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.gd)

## Project Structure

High-level folder overview:

- [assets](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/assets) - sprites, tiles, and visual assets
- [components](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/components) - reusable scene-level components such as camera logic
- [data](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/data) - `.tres` content definitions
- [entities](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities) - workers, animals, and runtime actors
- [scenes](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes) - world and UI scenes
- [systems](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems) - core gameplay systems and managers

## Running the Project

1. Open the project in Godot 4.
2. Open [project.godot](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/project.godot).
3. Run the main scene from the editor.

Note:

- This repository has been developed and adjusted in Godot editor workflows.
- Some verification in this workspace was done by code inspection because `godot` CLI was not available in the shell environment.

## Recommended Next Steps

Likely future directions:

- improve worker/animal/building animation
- polish the target system UX
- expand production chains
- add more world resource types and gathering tiers
- continue replacing temporary art with a unified visual style

## Additional Documentation

For a more detailed internal development summary, see:

- [REPORT.md](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/REPORT.md)
