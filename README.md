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

