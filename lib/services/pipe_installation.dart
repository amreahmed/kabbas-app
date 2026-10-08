const pipeInstallationCollection = 'pipe_installation_orders';
const pipeInstallationService = 'تأسيس مواسير التكييفات';

/// Accept Arabic and Persian digits as well as Latin digits.
int? parseUnitCount(String value) {
  var normalized = value.trim();
  for (var i = 0; i < 10; i++) {
    normalized = normalized
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  if (!RegExp(r'^\d+$').hasMatch(normalized)) return null;
  final count = int.tryParse(normalized);
  return count != null && count >= 1 && count <= 100 ? count : null;
}
