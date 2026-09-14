/// One date format for the WHOLE app — "05 Jan 2026" — instead of every
/// screen rolling its own dd/mm/yyyy or day/month abbreviation. Anywhere
/// that used to print `${d.day}/${d.month}/${d.year}` should use
/// [formatDate] instead, and anywhere that split month/day into two lines
/// (bill list rows) should use [monthAbbr] / [dayPad] from here so all of
/// them share the exact same month names.
const kMonthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const kMonthFullNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthAbbr(DateTime d) => kMonthAbbr[d.month - 1];

String dayPad(DateTime d) => d.day.toString().padLeft(2, '0');

String monthYear(DateTime d) => '${kMonthFullNames[d.month - 1]} ${d.year}';

/// "05 Jan 2026" — single-line date for tiles, pickers, transaction rows.
String formatDate(DateTime d) => '${dayPad(d)} ${monthAbbr(d)} ${d.year}';