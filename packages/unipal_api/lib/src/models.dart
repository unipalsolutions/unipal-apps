// Mirrors the API Resources in unipal-api (modules/*/Http/Resources). Keep both sides in step.

class User {
  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as String, name: json['name'] as String, email: json['email'] as String);

  final String id;
  final String name;
  final String email;
}

class Company {
  const Company({
    required this.id,
    required this.slug,
    required this.name,
    required this.nameAr,
    required this.isParent,
    this.role,
    this.abilities = const {},
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String,
    isParent: json['is_parent'] as bool? ?? false,
    role: json['role'] as String?,
    abilities: {...?(json['abilities'] as List?)?.cast<String>()},
  );

  final String id;

  /// group, advisors, tax or solutions: the same ids as the brands in unipal-brand.
  final String slug;
  final String name;
  final String nameAr;
  final bool isParent;
  final String? role;
  final Set<String> abilities;

  bool can(String ability) => abilities.contains(ability);
}

class Me {
  const Me({required this.user, required this.companies});

  factory Me.fromJson(Map<String, dynamic> json) => Me(
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    companies: [for (final c in json['companies'] as List) Company.fromJson(c as Map<String, dynamic>)],
  );

  final User user;
  final List<Company> companies;
}

const leadStages = [
  'new',
  'contacted',
  'meeting_scheduled',
  'meeting_held',
  'proposal_sent',
  'negotiation',
  'verbal_commit',
  'won',
  'lost',
  'paused',
];

class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.outcome,
    this.notes,
    this.user,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) => LeadActivity(
    id: json['id'] as String,
    type: json['type'] as String,
    outcome: json['outcome'] as String?,
    notes: json['notes'] as String?,
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    user: json['user'] == null ? null : User.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String id;
  final String type;
  final String? outcome;
  final String? notes;
  final DateTime occurredAt;
  final User? user;
}

class Lead {
  const Lead({
    required this.id,
    required this.reference,
    required this.stage,
    required this.source,
    required this.contactName,
    required this.probability,
    this.organizationName,
    this.email,
    this.phone,
    this.proposalValue,
    this.weightedValue,
    this.nextFollowUpOn,
    this.message,
    this.notes,
    this.owner,
    this.activities = const [],
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'] as String,
    reference: json['reference'] as String,
    stage: json['stage'] as String,
    source: json['source'] as String,
    contactName: json['contact_name'] as String,
    organizationName: json['organization_name'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    probability: json['probability'] as int,
    proposalValue: _decimal(json['proposal_value']),
    weightedValue: _decimal(json['weighted_value']),
    nextFollowUpOn: json['next_follow_up_on'] == null ? null : DateTime.parse(json['next_follow_up_on'] as String),
    message: json['message'] as String?,
    notes: json['notes'] as String?,
    owner: json['owner'] == null ? null : User.fromJson(json['owner'] as Map<String, dynamic>),
    activities: [
      for (final a in (json['activities'] as List?) ?? const []) LeadActivity.fromJson(a as Map<String, dynamic>),
    ],
  );

  final String id;
  final String reference;
  final String stage;
  final String source;
  final String contactName;
  final String? organizationName;
  final String? email;
  final String? phone;
  final int probability;

  /// AED.
  final double? proposalValue;
  final double? weightedValue;
  final DateTime? nextFollowUpOn;
  final String? message;
  final String? notes;
  final User? owner;
  final List<LeadActivity> activities;
}

class PipelineStage {
  const PipelineStage({required this.stage, required this.leads, required this.value, required this.weightedValue});

  final String stage;
  final int leads;
  final double value;
  final double weightedValue;
}

class Pipeline {
  const Pipeline({
    required this.stages,
    required this.openLeads,
    required this.weightedForecast,
    required this.followUpsDue,
  });

  factory Pipeline.fromJson(Map<String, dynamic> json) => Pipeline(
    stages: [
      for (final s in json['stages'] as List)
        PipelineStage(
          stage: s['stage'] as String,
          leads: s['leads'] as int,
          value: (s['value'] as num).toDouble(),
          weightedValue: (s['weighted_value'] as num).toDouble(),
        ),
    ],
    openLeads: json['open_leads'] as int,
    weightedForecast: (json['weighted_forecast'] as num).toDouble(),
    followUpsDue: json['follow_ups_due'] as int,
  );

  final List<PipelineStage> stages;
  final int openLeads;
  final double weightedForecast;
  final int followUpsDue;
}

const taskStatuses = ['backlog', 'todo', 'doing', 'review', 'done'];

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.projectName,
    this.assignee,
    this.dueOn,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    priority: json['priority'] as String,
    projectName: (json['project'] as Map<String, dynamic>?)?['name'] as String?,
    assignee: json['assignee'] == null ? null : User.fromJson(json['assignee'] as Map<String, dynamic>),
    dueOn: json['due_on'] == null ? null : DateTime.parse(json['due_on'] as String),
  );

  final String id;
  final String title;
  final String status;
  final String priority;
  final String? projectName;
  final User? assignee;
  final DateTime? dueOn;

  Task copyWith({String? status}) => Task(
    id: id,
    title: title,
    status: status ?? this.status,
    priority: priority,
    projectName: projectName,
    assignee: assignee,
    dueOn: dueOn,
  );
}

double? _decimal(Object? value) => value == null ? null : double.parse(value.toString());
