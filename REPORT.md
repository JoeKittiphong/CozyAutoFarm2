# Cozy Auto Farm 2 - Development Report

ไฟล์นี้สรุประบบหลักที่ถูกเพิ่มหรือรีแฟกเตอร์ในโปรเจกต์ช่วงล่าสุด เพื่อให้ทีมเห็นภาพรวมว่าเกมรองรับอะไรแล้วบ้าง และตอนนี้โครงสร้างเดินไปทางไหน

## Project Direction

โปรเจกต์ถูกปรับจากโค้ดแบบ hardcode หลายไฟล์ ไปสู่แนวทาง `data-driven + Godot-native workflow` มากขึ้น โดยแยกข้อมูลคอนเทนต์ออกเป็น resource files (`.tres`) และทำให้ระบบหลักอย่าง inventory, processors, animals, map layers, workers และ HUD อ่านข้อมูลจาก resource และ registry กลาง

เป้าหมายหลักของงานรอบนี้คือ:

- เพิ่มของใหม่ได้ง่ายขึ้นจาก data/resources
- ลด logic ซ้ำและ hardcode
- ทำให้ map, buildings, resources และ workers ขยายระบบต่อได้
- ทำให้ gameplay ไปทาง management มากขึ้น โดยยังเล่นง่าย

## Systems Added / Refactored

### 1. Centralized Game Data

ไฟล์แกนกลางคือ [game_data.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/game_data.gd)

สิ่งที่เพิ่ม:

- รวม constants กลางของ `item`, `blueprint`, `processor`, `animal`, `job`
- สแกน resource จากโฟลเดอร์อัตโนมัติ
  - `res://data/items`
  - `res://data/blueprints`
  - `res://data/processors`
  - `res://data/animals`
  - `res://data/world_resources`
- ทำ lookup/cache สำหรับ resource definitions
- รวม helper สำหรับราคาซื้อ, ราคาอัปเกรด, texture ตามเลเวล, worker domains, targetable items

ผลลัพธ์:

- เพิ่ม content ใหม่ง่ายขึ้น
- ลดการ preload รายไฟล์
- ลด typo จาก string กระจายหลายที่

### 2. Resource-Based Content System

มีการย้ายข้อมูล content หลักจาก dictionary ไปเป็น resource files แล้ว เช่น:

- `ItemDefinition`
- `BlueprintDefinition`
- `ProcessorDefinition`
- `AnimalDefinition`
- `WorldResourceDefinition`
- `ResourceAmountDefinition`

ผลลัพธ์:

- เพิ่ม item/building/processor/animal/world resource จาก `.tres` ได้
- เปิดแก้ค่าใน Inspector ได้ตรงๆ
- ลดภาระการแก้โค้ดเวลาปรับ balance

### 3. Dynamic Inventory

ไฟล์หลัก: [inventory_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/inventory_manager.gd)

สิ่งที่เปลี่ยน:

- เปลี่ยน stock จากตัวแปรรายชิ้นไปเป็น dictionary กลาง
- รองรับ item ใหม่อัตโนมัติตาม `GameData`
- มี API กลาง เช่น:
  - `get_item_stock`
  - `add_item`
  - `spend_item`
  - `has_resource_costs`
  - `spend_resource_costs`

ผลลัพธ์:

- เพิ่มไอเทมใหม่แล้ว inventory รองรับทันที
- ใช้เป็นฐานของระบบ target stock ได้

### 4. Generic Processor System

ไฟล์หลัก: [farm_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/farm_manager.gd)

สิ่งที่เพิ่ม:

- เปลี่ยนจากโรงงานเฉพาะรายตัวไปเป็น processor system กลาง
- ใช้ `ProcessorDefinition` กำหนด:
  - inputs
  - outputs
  - duration
  - storage positions
  - textures
- รองรับโรงงานใหม่โดยไม่ต้องเพิ่ม logic รายตัวมากเหมือนเดิม

ตัวอย่าง processor ที่มีแล้ว:

- Mill
- Bakery
- Tomato Factory
- Fish Cage
- Animal Feed Factory

### 5. Water Layer and Water Buildings

มีการเพิ่ม `WaterLayer` ใน world map และแยก logic ของพื้นผิวบก/น้ำออกจากกัน

ไฟล์หลัก:

- [world.tscn](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/world/world.tscn)
- [world.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/world/world.gd)
- [grid_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/grid_manager.gd)
- [map_scanner.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/map_scanner.gd)

สิ่งที่รองรับแล้ว:

- น้ำเป็นช่องที่เดินผ่านไม่ได้
- blueprint สามารถกำหนด `placement_surface`
  - `LAND`
  - `WATER`
- สิ่งปลูกสร้างบนน้ำอย่าง `Fish Cage` วางได้เฉพาะบน `WaterLayer`

### 6. Dynamic Map Scanning

ระบบแผนที่ไม่ล็อกแค่ 100x100 แบบเดิมแล้ว

สิ่งที่เปลี่ยน:

- `MapScanner` อ่าน `get_used_rect()` จาก TileMap layers จริง
- `GridManager` ปรับ region ของ AStar ตามพื้นที่ที่วาดใน editor
- รองรับการขยาย map ตามงานจริงใน editor โดยไม่ต้องกลับมาแก้โค้ดทุกครั้ง

ผลลัพธ์:

- วาด map กว้างขึ้นได้
- worker/pathfinding ใช้ขอบเขตจาก map จริง

### 7. World Resource Layer

มีการเพิ่ม `ResourceLayer` สำหรับทรัพยากรโลก เช่นต้นไม้และหิน

ไฟล์หลัก:

- [resource_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/world/resource_manager.gd)
- [world_resource_definition.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/data/world_resource_definition.gd)

ระบบนี้รองรับ:

- วางต้นไม้/หินบน `ResourceLayer`
- worker ไปเก็บไม้/หินได้
- ช่อง resource ตันการเดินและการก่อสร้างจนกว่าจะเก็บออก
- เก็บแล้วได้ item เข้าคลัง เช่น `WOOD`, `STONE`

นอกจากนี้ยังแยก blocker เป็น:

- obstacle blocker
- resource blocker

เพื่อให้ logic ของ map และการปลดล็อกช่องหลังเก็บทรัพยากรชัดเจนขึ้น

### 8. Construction Costs with Materials

การก่อสร้างไม่ใช้เงินอย่างเดียวแล้ว

สิ่งที่เพิ่ม:

- blueprint รองรับ `resource_costs`
- อาคารบางชนิดต้องใช้ไม้/หินร่วมกับเหรียญ
- HUD แสดงต้นทุนรวมของ building ได้

ผลลัพธ์:

- resource gathering มีความหมายต่อ economy
- วงจรการเล่นเริ่มผูกกันมากขึ้น

### 9. Animal System and Smart Feeding

ไฟล์หลัก:

- [farm_animal.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities/animals/farm_animal.gd)

สิ่งที่เพิ่ม:

- สัตว์ใช้งานผ่าน definition กลางมากขึ้น
- ระบบ smart feeding:
  - ถ้ามี `ANIMAL_FEED` จะใช้ก่อน
  - ถ้าไม่มี จะ fallback ไปอาหารพื้นฐานของสัตว์
- ระบบ feed points:
  - 1 ถุงอาหารสัตว์มีแต้มสะสมหลายครั้ง
  - วัว/ไก่ใช้แต้มไม่เท่ากัน

ผลลัพธ์:

- สัตว์ไม่ hardcode หนักแบบเดิม
- gameplay ฝั่งอาหารสัตว์มีความลึกขึ้น

### 10. Fish and Feed Production Chain

มีการเพิ่มสายการผลิตใหม่แล้ว เช่น:

- ปลา (`FISH`)
- อาหารสัตว์ (`ANIMAL_FEED`)
- Fish Cage
- Animal Feed Factory

ตัวอย่าง flow:

- แป้ง -> ปลา
- แป้ง + ข้าว + มันฝรั่ง -> อาหารสัตว์

ผลลัพธ์:

- ระบบแปรรูปเริ่มมี production chain ต่อเนื่อง
- inventory management สำคัญขึ้น

### 11. Worker Directional Sprites

ไฟล์หลัก: [worker.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities/worker/worker.gd)

สิ่งที่เพิ่ม:

- worker รองรับ sprite 4 ทิศ
  - front
  - back
  - left
  - right
- เปลี่ยนภาพตามทิศทางการเดิน
- ตอนนี้ใช้ placeholder จากภาพ worker เดิมก่อน และพร้อมเปลี่ยนเป็นภาพจริงภายหลัง

ผลลัพธ์:

- รองรับการอัปเกรดเป็นอนิเมชันในอนาคตได้ง่ายขึ้น

### 12. Worker House Domains

worker ถูกแยกตามสายงานด้วยบ้านเฉพาะทางแล้ว

บ้านที่มีตอนนี้:

- Farm House
- Gathering House
- Factory House

ผลของระบบนี้:

- worker แต่ละบ้านมี domain ของตัวเอง
- auto behavior ชัดขึ้น
- ลดปัญหา worker ทำทุกอย่างปนกัน
- ทำให้ logic ภาพรวมง่ายขึ้นกว่าระบบ assign งานละเอียดแบบเดิม

### 13. Worker Management Simplification

มีการลดบทบาทของ assignment system เดิมลง

จากเดิม:

- เลือก mode
- เลือก role
- เลือก target
- fallback

ตอนนี้:

- worker panel เน้นดูสถานะ
- การทำงานหลักถูกกำหนดโดยบ้าน/worker domain
- ระบบจึงอ่านง่ายและ debug ง่ายขึ้น

### 14. Target System

Target System เป็นระบบใหม่สำหรับบอก “ผลลัพธ์ที่ต้องการ” แทนการมอบหมายงานรายคน

ไฟล์หลัก:

- [inventory_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/inventory_manager.gd)
- [job_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/job_manager.gd)
- [hud.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.gd)
- [hud.tscn](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.tscn)

สิ่งที่เพิ่ม:

- ปุ่ม `Targets` บน HUD
- panel สำหรับตั้งเป้าสต็อกของแต่ละ item
- inventory เก็บ target และ shortage
- job system ให้ priority กับงานที่ช่วยผลิต item ที่ต่ำกว่าเป้า

ตัวอย่างการใช้งาน:

- ตั้ง `WHEAT = 50`
- ตั้ง `EGG = 10`
- ตั้ง `WOOD = 30`

เมื่อของต่ำกว่าเป้า:

- worker ของบ้านนั้นจะเร่งงานที่เกี่ยวข้องก่อน

เมื่อของถึงเป้า:

- worker จะกลับไปทำ auto behavior ปกติ

ระบบนี้เหมาะกับแนว management มากกว่า assignment รายคน เพราะผู้เล่นกำหนด “เป้าหมายของฟาร์ม” แทนการสั่งแรงงานทีละคน

### 15. Scene-Based HUD

HUD ถูกย้ายจาก code-heavy ไปเป็น scene-based มากขึ้น

สิ่งที่เพิ่ม:

- `hud.tscn`
- component scenes สำหรับปุ่มและรายการ
- warehouse panel
- targets panel
- worker management panel

ผลลัพธ์:

- layout แก้ง่ายใน editor
- รองรับการขยาย UI ในอนาคตได้ดีขึ้น

## Current Gameplay Summary

ตอนนี้โปรเจกต์รองรับวงจรการเล่นประมาณนี้แล้ว:

1. ปลูกพืชและเก็บเกี่ยว
2. เลี้ยงสัตว์และเก็บผลผลิต
3. ใช้โรงงานแปรรูปสินค้า
4. เก็บไม้/หินจากแผนที่
5. ใช้เงิน + วัตถุดิบในการก่อสร้าง
6. แยกแรงงานตามบ้าน
7. ตั้งเป้าสต็อกเพื่อเร่งการผลิตแบบอัตโนมัติ

## Notes for Future Work

สิ่งที่น่าต่อยอดหลังจากนี้:

- ทำ animation จริงให้ worker/animal/buildings
- ปรับ worker panel ให้เป็น status dashboard เต็มรูปแบบ
- ขยาย Target System ไปสู่เป้าหมายระดับ processor chain
- เพิ่มชนิดทรัพยากรโลกหลายระดับ เช่นไม้ใหญ่/หินแร่
- เพิ่ม art direction ชุดใหม่ให้เป็นสไตล์เดียวกันทั้งเกม

## Important Files

ไฟล์สำคัญของระบบปัจจุบัน:

- [systems/core/game_data.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/game_data.gd)
- [systems/core/inventory_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/core/inventory_manager.gd)
- [systems/farm/farm_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/farm_manager.gd)
- [systems/farm/job_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/farm/job_manager.gd)
- [systems/grid/grid_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/grid_manager.gd)
- [systems/grid/map_scanner.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/grid/map_scanner.gd)
- [systems/world/resource_manager.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/systems/world/resource_manager.gd)
- [scenes/world/world.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/world/world.gd)
- [scenes/ui/hud.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/scenes/ui/hud.gd)
- [entities/worker/worker.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities/worker/worker.gd)
- [entities/animals/farm_animal.gd](/D:/Program%20e-checksheet/program%20for%20AS-E-Checksheet/godot/CozyAutoFarm2/entities/animals/farm_animal.gd)

## Summary

โปรเจกต์ตอนนี้ไม่ได้เป็นแค่เกมปลูกผักพื้นฐานแล้ว แต่กำลังขยับไปเป็นเกมบริหารฟาร์มอัตโนมัติเต็มรูปแบบที่มี:

- economy loop
- production chain
- worker specialization
- map-driven world logic
- target-based automation

ฐานระบบตอนนี้แข็งแรงพอสำหรับขยาย content และปรับงานภาพต่อได้ในทิศทางที่ชัดขึ้นมาก
