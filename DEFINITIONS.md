# 📘 คู่มือการตั้งค่าสถาปัตยกรรมข้อมูล (Data Definitions Guide)

โปรเจกต์นี้ใช้ระบบ **Data-Driven Architecture** ซึ่งหมายความว่าคุณสามารถเพิ่มเนื้อหาเกมใหม่ๆ ได้ผ่านการสร้างไฟล์ `.tres` (Resource) โดยไม่ต้องแก้ไขโค้ด

---

## 1. 📦 ItemDefinition (ข้อมูลไอเทม)
**ตำแหน่งเก็บ**: `res://data/items/`
ใช้สำหรับนิยาม "สิ่งของ" ทุกอย่างที่คนงานสามารถถือได้ หรือเก็บไว้ในคลัง

| ช่อง (Field) | คำอธิบาย | ตัวอย่างค่า |
| :--- | :--- | :--- |
| **Item ID** | ไอดีอ้างอิงในระบบ (ต้องเป็นตัวพิมพ์ใหญ่และไม่ซ้ำ) | `WHEAT`, `FLOUR`, `CAKE` |
| **Label** | ชื่อที่จะแสดงผลใน UI | `Wheat`, `Premium Flour` |
| **Icon Path** | ไฟล์ภาพ `.png` ที่จะโชว์ในคลังสินค้า/HUD | `res://assets/sprites/wheat_icon.png` |
| **Sell Price** | ราคาขายต่อ 1 ชิ้น (Coins) | `10` |
| **Carry Amount** | จำนวนที่คนงานจะถือเมื่อมีการขนย้าย (มาตรฐานคือ 1) | `1` |

---

## 2. 🏗️ BlueprintDefinition (ข้อมูลการซื้อ/สร้าง)
**ตำแหน่งเก็บ**: `res://data/blueprints/`
ใช้สำหรับกำหนดรายการสินค้าในร้านค้า (Shop) และวิธีการวางลงบนแผนที่

| ช่อง (Field) | คำอธิบาย | ตัวอย่างค่า |
| :--- | :--- | :--- |
| **Blueprint ID** | ไอดีอ้างอิง (มักจะตรงกับ Item ID) | `WHEAT`, `BAKERY` |
| **Label** | ชื่อสินค้าที่แสดงในร้านค้า | `Wheat Seeds`, `Build Bakery` |
| **Stock Short** | ตัวอักษรย่อสำหรับแสดงผลในแถบสถานะ | `W`, `B` |
| **Base Price** | ราคาซื้อเริ่มต้น | `5.0` |
| **Growth** | ตัวคูณราคา (ราคาจะแพงขึ้นทุกครั้งที่ซื้อ) | `1.2` |
| **Placement Type** | ประเภทการวาง: `CROP`, `BUILDING`, `PROCESSOR` | `CROP` |
| **Crop Type** | (เฉพาะ CROP) ไอดีไอเทมที่จะได้เมื่อเก็บเกี่ยว | `WHEAT` |
| **Tile Type** | ชื่อประเภทไทล์ (ใช้ภายในระบบ) | `WHEAT`, `COOP` |
| **Processor Type** | (เฉพาะ PROCESSOR) เชื่อมกับ Processor ID | `BAKERY` |
| **Texture Path** | ภาพเมื่อวางเสร็จ (Level 1) | `res://assets/sprites/dirt.png` |
| **Level Textures** | อาเรย์ภาพตัวอาคารเลเวล 1-5 | `[res://...]` |
| **Level Sprout Textures** | อาเรย์ภาพต้นอ่อนเลเวล 1-5 | `[res://...]` |
| **Level Ready Textures** | อาเรย์ภาพตอนโตเลเวล 1-5 | `[res://...]` |

---

## 3. 🏭 ProcessorDefinition (ข้อมูลเครื่องจักร)
**ตำแหน่งเก็บ**: `res://data/processors/`
ใช้สำหรับกำหนดตรรกะการแปรรูปสินค้าของเครื่องจักร (โรงสี, เตาอบ)

| ช่อง (Field) | คำอธิบาย | ตัวอย่างค่า |
| :--- | :--- | :--- |
| **Processor Type** | ไอดีอ้างอิงของเครื่องจักร | `MILL`, `BAKERY` |
| **Label** | ชื่อเครื่องจักร | `Windmill`, `Royal Bakery` |
| **Base Duration** | เวลาที่ใช้ในการผลิตต่อ 1 ชุด (วินาที) | `5.0` |
| **Ready State Name** | ชื่อสถานะเมื่อผลิตเสร็จ | `READY` |
| **Ready Texture Path** | ภาพเมื่อผลิตเสร็จ (Default) | `res://assets/sprites/cake_icon.png` |
| **Ready Level Textures** | อาเรย์ภาพตอนผลิตเสร็จเลเวล 1-5 | `[res://...]` |
| **Idle Texture Path** | ภาพเครื่องจักรขณะว่างงาน (Default) | `res://assets/sprites/bakery_idle.png` |
| **Level Textures** | อาเรย์ภาพตัวเครื่องเลเวล 1-5 | `[res://...]` |

---

## 4. 🐮 AnimalDefinition (ข้อมูลสัตว์เลี้ยง)
**ตำแหน่งเก็บ**: `res://data/animals/`
ใช้สำหรับกำหนดพฤติกรรมสัตว์และผลผลิต

| ช่อง (Field) | คำอธิบาย | ตัวอย่างค่า |
| :--- | :--- | :--- |
| **Animal ID** | ไอดีของสัตว์ | `CHICKEN`, `COW` |
| **Label** | ชื่อสัตว์ | `Hen`, `Dairy Cow` |
| **Price** | ราคาซื้อ | `50` |
| **Level Textures** | อาเรย์ภาพตัวสัตว์เลเวล 1-5 | `[res://...]` |

---

## 💡 วิธีการสร้าง Resource ใหม่ใน Godot
1. คลิกขวาในโฟลเดอร์ที่ต้องการ (เช่น `res://data/items/`)
2. เลือก **New Resource...**
3. ค้นหาคลาสที่ต้องการ (เช่น `ItemDefinition`)
4. ตั้งชื่อไฟล์ (แนะนำเป็นตัวพิมพ์เล็กทั้งหมด เช่น `egg.tres`)
5. แก้ไขค่าต่างๆ ในหน้า **Inspector** ฝั่งขวาของจอ
