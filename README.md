# Daybook · My Mini To-Do
สมุดกิจกรรมส่วนตัวภาษาไทยสำหรับโทรศัพท์ หน้าแรกมี 3 กิจกรรม แตะช่องสี่เหลี่ยมเพื่อติ๊กหรือยกเลิก แตะชื่อหรือลูกศรเพื่อดูรายละเอียดและขั้นตอน แอปบันทึกสถานะลงเครื่องด้วย shared_preferences

## เปิดจากซอร์ส
ใช้ Flutter 3.41.6 และ Dart 3.11 หรือรุ่นที่เข้ากันได้
```sh
flutter pub get
flutter devices
flutter run
```
เลือกโทรศัพท์ Android ที่เปิด USB debugging หรือเลือก iPhone ที่ตั้งค่า signing ใน Xcode แล้ว สำหรับเว็บบนคอมพิวเตอร์ใช้ `flutter run -d chrome`

## เปิดบน iPhone หรือ Android ผ่าน Wi-Fi
ต่อโทรศัพท์และคอมพิวเตอร์เข้ากับ Wi-Fi เดียวกัน แล้วรันบนคอมพิวเตอร์
```sh
flutter build web --no-web-resources-cdn
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
```
เปิด Safari หรือ Chrome บนมือถือ ใส่ที่อยู่ IP ของคอมพิวเตอร์ ตามด้วยพอร์ต 8080 เช่น `http://192.168.1.10:8080`

## ข้อกำหนดการบ้าน
- ใน lib/main.dart หน้า Home ใช้ ListView.builder สร้างรายการ และใช้ ListTile แสดงแต่ละกิจกรรม
- Checkbox เรียก change ซึ่งใช้ setState อัปเดตรายการและแถบความคืบหน้า
- open เรียก Navigator.push กับ MaterialPageRoute เพื่อเปิดหน้า Details ของกิจกรรมที่เลือก
- ทดสอบด้วย `flutter test` และตรวจโค้ดด้วย `flutter analyze`

ภาพปกวาดด้วย CustomPainter ใน lib/journal_art.dart ลิขสิทธิ์ฟอนต์อยู่ใน assets/fonts/LICENSE.txt

## ปฏิทิน
แตะ **ปฏิทิน** ที่หน้าแรก เลือกเดือนและวันที่ แล้วแตะ **เปิดกิจกรรมวันที่เลือก** วันที่มีจุดสีทองคือวันที่ทำบางส่วน จุดสีเขียวคือวันที่ทำครบ ทั้งสามกิจกรรมมีสถานะแยกกันในแต่ละวัน กด **วันนี้** เพื่อกลับไปวันที่ปัจจุบัน


## Android Emulator และการเชื่อมต่อ Supabase

เปิด Android Emulator จาก Device Manager แล้วใช้ `flutter run -d emulator-5554`
(ดูรหัสจริงจาก `flutter devices`) โหมดนี้เก็บข้อมูลเฉพาะบนเครื่องตามเดิม

หากต้องการเปิดโหมดเชื่อมบัญชีบน Android ให้ทำตามขั้นตอนนี้ในโปรเจกต์ทดสอบก่อน

1. ใช้ migration ใน `supabase/migrations/` กับฐานข้อมูล Supabase โปรเจกต์ของคุณ
   ตารางเปิด RLS เพื่อจำกัดการอ่านและเขียนตามผู้ใช้ที่ล็อกอิน
2. เปิด Google provider ใน Supabase Auth ตั้งค่า Google OAuth ตามคู่มือ Supabase
   และเพิ่ม `com.example.my_mini_todo://auth/callback` ใน Redirect URLs สำหรับ Emulator
3. รันแอปพร้อม URL และ **publishable key** จาก Supabase ใช้ OAuth client secret
   เฉพาะใน Supabase Dashboard และเก็บ service role key ไว้ฝั่งเซิร์ฟเวอร์

```sh
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE_ME
```

ระบบใช้ OAuth ผ่านเบราว์เซอร์ภายนอก พร้อม PKCE และเก็บ session กับ code verifier
ใน Android secure storage แอปโหลดความคืบหน้าตามบัญชีจากฐานข้อมูลตอนเข้าใช้งาน
และเมื่อกดโหลดข้อมูลล่าสุด ถ้าโหลดไม่ได้จะแสดงแคชของบัญชีนั้นที่อยู่ในเครื่อง
การติ๊กในโหมด Supabase ต้องเชื่อมต่อเพื่อบันทึก ข้อมูลเดิมจากโหมด local
ยังอยู่ในเครื่องและแยกจากข้อมูลของบัญชี Supabase

สำหรับ Android รุ่นเผยแพร่ ให้ใช้ application ID และ release signing ของแอปจริง
ตั้ง Android App Link บนโดเมนที่ควบคุม โดยเผยแพร่ไฟล์
`/.well-known/assetlinks.json` ให้ตรงกับ application ID และ SHA-256 fingerprint
ของกุญแจที่ใช้เซ็นแอป เพิ่ม URL `https://YOUR_DOMAIN/callback` ใน Supabase Redirect URLs
แล้ว build โดยส่ง `ORG_GRADLE_PROJECT_daybookAuthHost=YOUR_DOMAIN` ให้ Gradle
และเพิ่ม `--dart-define=DAYBOOK_AUTH_REDIRECT=https://YOUR_DOMAIN/callback`
นอกเหนือจากค่า Supabase ด้านบน
