import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  /// 1. สูตรคำนวณองศาระหว่างจุด 3 จุด (เช่น ไหล่-ศอก-ข้อมือ)
  static double calculateAngle(
      PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double result = math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    result = result * 180 / math.pi;
    result = result.abs();
    if (result > 180) {
      result = 360.0 - result;
    }
    return result;
  }

  /// 2. แปลง Pose ให้เป็นชุดตัวเลของศา (Feature Vector สำหรับ KNN)
  /// สนใจ 6 มุมหลักที่ระบุท่าทางส่วนบนได้ชัดเจนที่สุด
  static List<double> getPoseAngles(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // ตรวจสอบจุดสำคัญที่จำเป็นต้องใช้
    const requiredTypes = [
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftHip
    ];

    for (var type in requiredTypes) {
      if (!landmarks.containsKey(type)) return [];
    }

    final rs = landmarks[PoseLandmarkType.rightShoulder]!;
    final re = landmarks[PoseLandmarkType.rightElbow]!;
    final rw = landmarks[PoseLandmarkType.rightWrist]!;
    final rh = landmarks[PoseLandmarkType.rightHip]!;

    final ls = landmarks[PoseLandmarkType.leftShoulder]!;
    final le = landmarks[PoseLandmarkType.leftElbow]!;
    final lw = landmarks[PoseLandmarkType.leftWrist]!;
    final lh = landmarks[PoseLandmarkType.leftHip]!;

    return [
      calculateAngle(rs, re, rw), // 1. ศอกขวา
      calculateAngle(re, rs, rh), // 2. รักแร้ขวา (แขนเทียบกับลำตัว)
      calculateAngle(ls, le, lw), // 3. ศอกซ้าย
      calculateAngle(le, ls, lh), // 4. รักแร้ซ้าย
      calculateAngle(re, rs, ls), // 5. กางแขนขวาเทียบกับแนวไหล่
      calculateAngle(le, ls, rs), // 6. กางแขนซ้ายเทียบกับแนวไหล่
    ];
  }

  /// 3. ตรวจสอบความเหมือน (KNN Distance Check)
  /// คำนวณค่าเฉลี่ยความผิดพลาด (Mean Absolute Error)
  static bool isMatch(
      List<double> savedAngles, List<double> currentAngles, double threshold) {
    if (savedAngles.length != currentAngles.length) return false;

    double totalError = 0;
    for (int i = 0; i < savedAngles.length; i++) {
      totalError += (savedAngles[i] - currentAngles[i]).abs();
    }

    double meanError = totalError / savedAngles.length;

    // แปลง Threshold (0.1 - 0.5) เป็นองศาที่ยอมรับได้
    // ค่ามาตรฐาน 0.25 จะยอมให้ผิดได้เฉลี่ย ~25 องศา
    double allowedErrorDegrees = 50.0 - (threshold * 100.0);
    return meanError <= allowedErrorDegrees;
  }
}
