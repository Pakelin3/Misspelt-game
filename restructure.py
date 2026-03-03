import os
import subprocess

# Run from project root

mapping = {
    # characters/player
    "scenes/Player.gd": "characters/player/Player.gd",
    "scenes/Player.tscn": "characters/player/Player.tscn",
    "scenes/PlayerStats.gd": "characters/player/PlayerStats.gd",
    "scenes/mage_stats.tres": "characters/player/mage_stats.tres",
    "scenes/farmer_stats.tres": "characters/player/farmer_stats.tres",
    "scenes/warlock_stats.tres": "characters/player/warlock_stats.tres",
    "scenes/erudit_stats.tres": "characters/player/erudit_stats.tres",
    "scenes/WeaponPivot.gd": "characters/player/WeaponPivot.gd",

    # characters/enemies
    "scenes/Enemy.gd": "characters/enemies/Enemy.gd",
    "scenes/Enemy.tscn": "characters/enemies/Enemy.tscn",
    "scenes/BossEnye.gd": "characters/enemies/BossEnye.gd",
    "scenes/BossEnye.tscn": "characters/enemies/BossEnye.tscn",
    "scenes/EnemySpawner.gd": "characters/enemies/EnemySpawner.gd",

    # core/autoloads
    "scenes/EventBus.gd": "core/autoloads/EventBus.gd",
    "GameManager.gd": "core/autoloads/GameManager.gd",

    # core/level
    "scenes/Game.gd": "core/level/Game.gd",
    "scenes/Game.tscn": "core/level/Game.tscn",

    # ui/hud
    "scenes/HUD.gd": "ui/hud/HUD.gd",
    "scenes/CardUI.gd": "ui/hud/CardUI.gd",

    # entities/items
    "scenes/LetterDrop.gd": "entities/items/LetterDrop.gd",
    "scenes/LetterDrop.tscn": "entities/items/LetterDrop.tscn",
    "scenes/XPGem.gd": "entities/items/XPGem.gd",
    "scenes/XPGem.tscn": "entities/items/XPGem.tscn",

    # entities/projectiles
    "scenes/Projectile.gd": "entities/projectiles/Projectile.gd",
    "scenes/Projectile.tscn": "entities/projectiles/Projectile.tscn",
    "scenes/TildeProjectile.gd": "entities/projectiles/TildeProjectile.gd",
    "scenes/TildeProjectile.tscn": "entities/projectiles/TildeProjectile.tscn",

    # entities/misc
    "scenes/ShadowContainer.tscn": "entities/misc/ShadowContainer.tscn"
}

# 1. Create directories
dirs = set(os.path.dirname(v) for v in mapping.values())
for d in dirs:
    os.makedirs(d, exist_ok=True)

# 2. Gather all files to process BEFORE moving to update references
target_extensions = ('.gd', '.tscn', '.tres')
files_to_update = []
for root, _, files in os.walk("."):
    if ".git" in root or ".godot" in root:
        continue
    for f in files:
        if f.endswith(target_extensions) or f == "project.godot":
            files_to_update.append(os.path.join(root, f))

# Read and replace content in all files
for filepath in files_to_update:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        modified = False
        
        # Replace exact full paths
        for old_path, new_path in mapping.items():
            res_old = "res://" + old_path
            res_new = "res://" + new_path
            if res_old in content:
                content = content.replace(res_old, res_new)
                modified = True
                
        # Handle the one dynamic path in Player.gd
        if '"res://scenes/" + skin_id' in content:
            content = content.replace('"res://scenes/" + skin_id', '"res://characters/player/" + skin_id')
            modified = True
                
        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated references in {filepath}")
    except Exception as e:
        print(f"Error updating {filepath}: {e}")

# 3. Move files AND their .uid metadata files
for old_path, new_path in mapping.items():
    if os.path.exists(old_path):
        subprocess.run(["git", "mv", old_path, new_path])
        print(f"Moved {old_path} -> {new_path}")
        
    old_uid = old_path + ".uid"
    new_uid = new_path + ".uid"
    if os.path.exists(old_uid):
        subprocess.run(["git", "mv", old_uid, new_uid])
        
    old_import = old_path + ".import"
    new_import = new_path + ".import"
    if os.path.exists(old_import):
        subprocess.run(["git", "mv", old_import, new_import])

# Remove empty scenes folder
if os.path.exists("scenes") and not os.listdir("scenes"):
    os.rmdir("scenes")
    print("Removed empty scenes directory")
