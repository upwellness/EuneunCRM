# EuneunCRM

CRM ส่วนตัว + project hub แบบ single-file web app — เก็บลูกค้าทุกสายธุรกิจไว้ที่เดียว · track สถานะ + โน้ตประวัติ + วางแผนตามต่อ · เปิดแอปมา "หน้าแรกบอกว่าต้องตามใคร".

**Live:** https://euneun-crm.vercel.app · **CI:** TONPALEARN (gold/teal/violet · glass · dark/light อัตโนมัติ)

---

## ฟีเจอร์
- **Dashboard** — KPI (ทั้งหมด / Active / ต้องตาม / ยังไม่วางแผน / ปิดได้เดือนนี้) + "ใครควรตาม" + กราฟแยก business/สถานะ
- **ลูกค้า** — ค้นหา + กรอง (business / สถานะ / ต้องตาม / ยังไม่วางแผน / ซ่อนชุมชน)
- **ตามงาน** — จัด bucket: ค้าง / วันนี้ / ไม่ได้ตามนาน / เร็วๆ นี้ / ยังไม่วางแผน
- **หน้าลูกค้า** — เปลี่ยนสถานะ (7 ระดับ) · บันทึกโน้ต (เซ็ตวันคุยล่าสุดอัตโนมัติ) · ตั้งแผนถัดไป + วันที่ · ไทม์ไลน์ประวัติ
- **Follow-up engine** — คำนวณ "หายไป N วัน" → เด้งคนที่ต้องตาม (เกณฑ์ 14 วัน · ดูแลยาว 30 วัน)
- Dark/Light ตามระบบ + ปรับขนาดฟอนต์ + mobile responsive

## เทคนิค
- Single-file `index.html` — React 18 (UMD) + Babel standalone (**classic runtime**) + CSS variables ไม่พึ่ง build
- **Supabase** เก็บข้อมูล (cross-device) ผ่าน RPC ที่ล็อกด้วย **PIN** — anon key อ่าน table ตรงไม่ได้
- localStorage = cache ออฟไลน์ + Export/Import JSON สำรอง

## ความปลอดภัย
- ข้อมูลลูกค้า (ชื่อ + โน้ต) อยู่ใน Supabase เท่านั้น — **ไม่อยู่ใน repo นี้**
- เข้าใช้ต้องกรอก **PIN** (เก็บใน Supabase, ไม่อยู่ใน code) → ทุก request ผ่าน SECURITY DEFINER RPC ที่เช็ค PIN
- anon key ฝังใน `index.html` ได้ (public by design) เพราะ RLS เปิด + ไม่มี policy ให้ anon แตะ table ตรง

## ติดตั้ง (สำหรับ fork ใหม่)
1. สร้าง schema ใน Supabase: รัน `supabase/schema.sql` (แก้ `CHANGE_ME` เป็น PIN ของคุณก่อน)
2. ใส่ `SB_URL` + `SB_ANON` ใน `index.html`
3. seed ข้อมูลตั้งต้น (ออปชัน): สร้าง `seed-embed.js` (`window.CRM_SEED = {...}`) — แอปจะ push ขึ้น cloud ครั้งแรกถ้า cloud ว่าง
4. deploy เป็น static site (Vercel) — ไม่ต้องตั้ง build

## โครงสร้าง
```
index.html            # แอปทั้งตัว
supabase/schema.sql   # ตาราง crm_* + RPC ล็อก PIN (ตั้ง PIN เอง)
README.md
```
> ข้อมูลจริง (seed-embed.js · data/ · build_seed.py · specs) ถูก gitignore ไว้ — ไม่ publish
