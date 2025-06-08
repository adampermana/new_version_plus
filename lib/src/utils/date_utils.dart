import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DateUtil {
  static Map<String, String> get _indonesianMonthMapping => {
        // Bulan penuh
        'januari': 'January',
        'februari': 'February',
        'maret': 'March',
        'april': 'April',
        'mei': 'May',
        'juni': 'June',
        'juli': 'July',
        'agustus': 'August',
        'september': 'September',
        'oktober': 'October',
        'november': 'November',
        'desember': 'December',
        // Bulan singkat
        'jan': 'Jan',
        'feb': 'Feb',
        'mar': 'Mar',
        'apr': 'Apr',
        'jun': 'Jun',
        'jul': 'Jul',
        'ags': 'Aug',
        'sep': 'Sep',
        'okt': 'Oct',
        'nov': 'Nov',
        'des': 'Dec',
      };

// Method untuk convert tanggal Indonesia ke format yang bisa di-parse

  static String _convertIndonesianDateToEnglish(String dateStr) {
    String result = dateStr.toLowerCase().trim();
    _indonesianMonthMapping.forEach((indonesian, english) {
      result = result.replaceAll(indonesian, english);
    });
    return result;
  }
  // static String _convertIndonesianDateToEnglish(String dateStr) {
  //   String result = dateStr.toLowerCase().trim();
  //   final monthMapping = _indonesianMonthMapping();

  //   // Replace Indonesian month names with English ones
  //   monthMapping.forEach((indonesian, english) {
  //     result = result.replaceAll(indonesian, english);
  //   });

  //   return result;
  // }

// Method untuk parsing tanggal dengan support multi-bahasa
  static DateTime? parseMultiLanguageDate(String dateStr, String countryCode) {
    try {
      String cleanDateStr = dateStr.trim();

      // Jika country code adalah Indonesia, convert dulu ke format Inggris
      if (countryCode.toLowerCase() == 'id') {
        cleanDateStr = _convertIndonesianDateToEnglish(cleanDateStr);
      }

      // Daftar format tanggal yang mungkin
      final formats = [
        'MMM d, yyyy', // Mar 15, 2024
        'MMMM d, yyyy', // March 15, 2024
        'd MMM yyyy', // 15 Mar 2024
        'd MMMM yyyy', // 15 March 2024
        'yyyy-MM-dd', // 2024-03-15
        'MM/dd/yyyy', // 03/15/2024
        'dd/MM/yyyy', // 15/03/2024
        'dd-MM-yyyy', // 15-03-2024
        'yyyy/MM/dd', // 2024/03/15
      ];

      // Coba parse dengan berbagai format
      for (final format in formats) {
        try {
          return DateFormat(format, 'en_US').parse(cleanDateStr);
        } catch (e) {
          continue;
        }
      }

      // Jika masih gagal, coba dengan format Indonesia langsung
      if (countryCode.toLowerCase() == 'id') {
        final indonesianFormats = [
          'dd MMMM yyyy', // 15 Maret 2024
          'd MMMM yyyy', // 15 Maret 2024
          'dd MMM yyyy', // 15 Mar 2024
          'd MMM yyyy', // 15 Mar 2024
        ];

        for (final format in indonesianFormats) {
          try {
            return DateFormat(format, 'id_ID').parse(dateStr);
          } catch (e) {
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return null;
    }
  }
}
