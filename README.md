# 🚀 rally_ui

> **MLKit Gesture-Controlled IoT Interface**  
> แอปพลิเคชัน Flutter สำหรับควบคุมอุปกรณ์ IoT ผ่านการตรวจจับท่าทาง (Movement / Gesture Recognition) โดยใช้ Google ML Kit

---

## 📌 Features

- **Gesture Control**: ตรวจจับการเคลื่อนไหวผ่านกล้องเพื่อส่งคำสั่งไปยังอุปกรณ์ IoT
- **Real-time Processing**: ประมวลผลภาพและท่าทางอย่างรวดเร็วด้วย ML Kit
- **Cross-Platform UI**: อินเทอร์เฟซที่ออกแบบด้วย Flutter

---

## 🛠️ Prerequisites & Setup

- **Flutter SDK**: `3.22.x`
- **Dart SDK**: เวอร์ชันที่รองรับกับ Flutter 3.22
- **JDK**: OpenJDK 17
- **Android Studio Components**: NDK, CMake, Android SDK Platform-Tools

---

## 🚀 Quick Start (Copy & Paste)

ก๊อปปี้คำสั่งด้านล่างไปวางใน Terminal เพื่อเริ่มรันโปรเจกต์:

```bash
# 1. สร้างโปรเจกต์และเข้าโฟลเดอร์
flutter create rally_ui
cd rally_ui

# 2. หลังจาก Copy โค้ด pages และ pubspec.yaml เข้ามาแล้ว ให้รันคำสั่งนี้เพื่อ Quick Fix Dependencies
flutter clean
flutter pub get
flutter pub upgrade

# 3. รันแอปพลิเคชัน
flutter run
