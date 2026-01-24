import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  /// 1. สูตรคำนวณองศาระหว่างจุด 3 จุด (เช่น ไหล่-ศอก-ข้อมือ)
  /// คืนค่าเป็น 0 - 180 องศา
  static double calculateAngle(
      PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    // หาผลต่างของพิกัด
    double result = math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);

    // แปลงเรเดียนเป็นองศา
    result = result * 180 / math.pi;

    // ทำให้เป็นค่าบวก (Absolute)
    result = result.abs();

    // ถ้าเกิน 180 องศา ให้พับกลับมา (เช่น 350 องศา คือ 10 องศา)
    if (result > 180) {
      result = 360.0 - result;
    }

    return result;
  }

  /// 2. ฟังก์ชันแปลง "ท่าทางทั้งตัว" ให้กลายเป็น "ชุดตัวเลของศา" (Feature Vector)
  /// เราจะสนใจแค่มุมสำคัญๆ ของร่างกายส่วนบน
  static List<double> getPoseAngles(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // ต้องมีจุดสำคัญครบ ไม่งั้นคำนวณไม่ได้
    if (!landmarks.containsKey(PoseLandmarkType.rightShoulder) ||
        !landmarks.containsKey(PoseLandmarkType.rightElbow) ||
        !landmarks.containsKey(PoseLandmarkType.rightWrist) ||
        !landmarks.containsKey(PoseLandmarkType.rightHip) ||
        !landmarks.containsKey(PoseLandmarkType.leftShoulder) ||
        !landmarks.containsKey(PoseLandmarkType.leftElbow) ||
        !landmarks.containsKey(PoseLandmarkType.leftWrist) ||
        !landmarks.containsKey(PoseLandmarkType.leftHip)) {
      return [];
    }

    final rShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final rElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final rWrist = landmarks[PoseLandmarkType.rightWrist]!;
    final rHip = landmarks[PoseLandmarkType.rightHip]!;

    final lShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final lElbow = landmarks[PoseLandmarkType.leftElbow]!;
    final lWrist = landmarks[PoseLandmarkType.leftWrist]!;
    final lHip = landmarks[PoseLandmarkType.leftHip]!;

    return [
      // 1. มุมศอกขวา (กางแขน/หุบแขน)
      calculateAngle(rShoulder, rElbow, rWrist),

      // 2. มุมรักแร้ขวา (ยกแขนสูง/ต่ำ เทียบกับลำตัว)
      calculateAngle(rElbow, rShoulder, rHip),

      // 3. มุมศอกซ้าย
      calculateAngle(lShoulder, lElbow, lWrist),

      // 4. มุมรักแร้ซ้าย
      calculateAngle(lElbow, lShoulder, lHip),

      // (เสริม) มุมหัวไหล่ 2 ข้างเทียบกัน (ดูความเอียงตัว)
      calculateAngle(rShoulder, lShoulder, lHip),
    ];
  }

  /// 3. ฟังก์ชันเปรียบเทียบความเหมือน (Match)
  /// savedAngles: องศาของท่าที่บันทึกไว้
  /// currentAngles: องศาที่กล้องเห็นตอนนี้
  /// threshold: ความเข้มงวด (ยิ่งน้อยยิ่งต้องเป๊ะ)
  static bool isMatch(
      List<double> savedAngles, List<double> currentAngles, double threshold) {
    if (savedAngles.length != currentAngles.length) return false;

    double totalError = 0;

    for (int i = 0; i < savedAngles.length; i++) {
      // หาผลต่างของแต่ละมุม
      double diff = (savedAngles[i] - currentAngles[i]).abs();
      totalError += diff;
    }

    // หาค่าเฉลี่ยความผิดพลาด (Mean Absolute Error)
    double meanError = totalError / savedAngles.length;

    // ปกติ threshold เราตั้งไว้เป็น 0.0 - 1.0 ในหน้า UI
    // เราต้องแปลงให้เป็น "องศาที่ยอมรับได้"
    // เช่น threshold 0.5 (กลางๆ) อาจจะยอมให้ผิดได้เฉลี่ย 25 องศา
    // threshold 0.9 (เข้มมาก) อาจจะยอมให้ผิดได้แค่ 10 องศา

    // สูตรแปลง: threshold 0.1 (ง่าย) -> ยอมผิด 40 องศา
    //           threshold 0.5 (กลาง) -> ยอมผิด 20 องศา
    //           threshold 0.9 (ยาก)  -> ยอมผิด 10 องศา
    double allowedErrorDegrees = 45.0 - (threshold * 40.0);

    // ถ้าค่าผิดพลาดเฉลี่ยน้อยกว่าที่ยอมรับได้ แปลว่า "ท่าเหมือนกัน" ✅
    return meanError <= allowedErrorDegrees;
  }
}
