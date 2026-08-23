import 'package:flutter/material.dart' show IconData, Icons;

enum SkillCategory {
  frontend,
  backend,
  mobile,
  devops,
  cloud,
  database,
  dataEngineering,
  uiUx,
  unknown,
}

enum SkillProficiency { beginner, intermediate, advanced }

SkillProficiency skillProficiencyFromString(String? value) {
  switch (value) {
    case 'INTERMEDIATE':
      return SkillProficiency.intermediate;
    case 'ADVANCED':
      return SkillProficiency.advanced;
    case 'BEGINNER':
    default:
      return SkillProficiency.beginner;
  }
}

String skillProficiencyToApiString(SkillProficiency level) {
  switch (level) {
    case SkillProficiency.beginner:
      return 'BEGINNER';
    case SkillProficiency.intermediate:
      return 'INTERMEDIATE';
    case SkillProficiency.advanced:
      return 'ADVANCED';
  }
}

extension SkillProficiencyLabel on SkillProficiency {
  String get label {
    switch (this) {
      case SkillProficiency.beginner:
        return 'Beginner';
      case SkillProficiency.intermediate:
        return 'Intermediate';
      case SkillProficiency.advanced:
        return 'Advanced';
    }
  }

  String get shortLabel {
    switch (this) {
      case SkillProficiency.beginner:
        return 'Beg';
      case SkillProficiency.intermediate:
        return 'Int';
      case SkillProficiency.advanced:
        return 'Adv';
    }
  }
}

SkillCategory skillCategoryFromString(String? value) {
  switch (value) {
    case 'FRONTEND':
      return SkillCategory.frontend;
    case 'BACKEND':
      return SkillCategory.backend;
    case 'MOBILE':
      return SkillCategory.mobile;
    case 'DEVOPS':
      return SkillCategory.devops;
    case 'CLOUD':
      return SkillCategory.cloud;
    case 'DATABASE':
      return SkillCategory.database;
    case 'DATA_ENGINEERING':
      return SkillCategory.dataEngineering;
    case 'UI_UX':
      return SkillCategory.uiUx;
    default:
      return SkillCategory.unknown;
  }
}

String skillCategoryToApiString(SkillCategory category) {
  switch (category) {
    case SkillCategory.frontend:
      return 'FRONTEND';
    case SkillCategory.backend:
      return 'BACKEND';
    case SkillCategory.mobile:
      return 'MOBILE';
    case SkillCategory.devops:
      return 'DEVOPS';
    case SkillCategory.cloud:
      return 'CLOUD';
    case SkillCategory.database:
      return 'DATABASE';
    case SkillCategory.dataEngineering:
      return 'DATA_ENGINEERING';
    case SkillCategory.uiUx:
      return 'UI_UX';
    case SkillCategory.unknown:
      return 'BACKEND';
  }
}

extension SkillCategoryLabel on SkillCategory {
  String get label {
    switch (this) {
      case SkillCategory.frontend:
        return 'Frontend';
      case SkillCategory.backend:
        return 'Backend';
      case SkillCategory.mobile:
        return 'Mobile';
      case SkillCategory.devops:
        return 'DevOps';
      case SkillCategory.cloud:
        return 'Cloud';
      case SkillCategory.database:
        return 'Database';
      case SkillCategory.dataEngineering:
        return 'Data Engineering';
      case SkillCategory.uiUx:
        return 'UI/UX';
      case SkillCategory.unknown:
        return 'Other';
    }
  }

  /// Default icon
  IconData get icon {
    switch (this) {
      case SkillCategory.frontend:
        return Icons.web_outlined;
      case SkillCategory.backend:
        return Icons.dns_outlined;
      case SkillCategory.mobile:
        return Icons.smartphone_outlined;
      case SkillCategory.devops:
        return Icons.settings_suggest_outlined;
      case SkillCategory.cloud:
        return Icons.cloud_outlined;
      case SkillCategory.database:
        return Icons.storage_outlined;
      case SkillCategory.dataEngineering:
        return Icons.insights_outlined;
      case SkillCategory.uiUx:
        return Icons.palette_outlined;
      case SkillCategory.unknown:
        return Icons.extension_outlined;
    }
  }
}

class Skill {
  final int id;
  final String name;
  final SkillCategory category;
  final String rawCategory;

  final String? description;

  final SkillProficiency? proficiency;
  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.rawCategory,
    this.description,
    this.proficiency,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    final raw = (json['category'] as String?) ?? '';

    return Skill(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: skillCategoryFromString(raw),
      rawCategory: raw,
      description: json['description'] as String?,
      proficiency: json['proficiency'] == null
          ? null
          : skillProficiencyFromString(json['proficiency'] as String?),
    );
  }
  Skill withProficiency(SkillProficiency level) {
    return Skill(
      id: id,
      name: name,
      category: category,
      rawCategory: rawCategory,
      description: description,
      proficiency: level,
    );
  }

  /// Display label for the UI.
  String get categoryLabel {
    if (category != SkillCategory.unknown) {
      return category.label;
    }

    if (rawCategory.isEmpty) {
      return 'Other';
    }

    return rawCategory
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0]}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Icon for the category.
  IconData get categoryIcon {
    if (category != SkillCategory.unknown) {
      return category.icon;
    }

    return Icons.extension_outlined;
  }
}
