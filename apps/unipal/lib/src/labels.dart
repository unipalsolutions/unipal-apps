import 'package:intl/intl.dart';

// Arabic labels for the API's enum values (same wording as the web hub).

const stageLabels = {
  'new': 'جديد',
  'contacted': 'تم التواصل',
  'meeting_scheduled': 'اجتماع مجدول',
  'meeting_held': 'تم الاجتماع',
  'proposal_sent': 'عرض مُرسل',
  'negotiation': 'تفاوض',
  'verbal_commit': 'موافقة مبدئية',
  'won': 'تم الكسب',
  'lost': 'خسارة',
  'paused': 'متوقف',
};

const sourceLabels = {
  'referral': 'إحالة',
  'website': 'الموقع',
  'linkedin': 'LinkedIn',
  'cold_call': 'اتصال مباشر',
  'event': 'فعالية',
  'existing_client': 'عميل حالي',
  'partner': 'شريك',
  'other': 'أخرى',
};

const activityLabels = {
  'call': 'مكالمة',
  'email': 'بريد',
  'meeting': 'اجتماع',
  'proposal': 'عرض سعر',
  'follow_up': 'متابعة',
  'note': 'ملاحظة',
};

const statusLabels = {
  'backlog': 'الأفكار',
  'todo': 'للتنفيذ',
  'doing': 'قيد العمل',
  'review': 'مراجعة',
  'done': 'مكتمل',
};

const priorityLabels = {'high': 'عاجل', 'normal': 'عادي', 'low': 'منخفض'};

String formatAed(num? value) => value == null ? '—' : 'AED ${NumberFormat.decimalPattern('en').format(value.round())}';

String formatDate(DateTime? date) => date == null ? '—' : DateFormat.MMMd('ar').format(date);
