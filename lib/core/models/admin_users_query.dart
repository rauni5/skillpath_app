enum UserStatusFilter { all, admin, active, inactive }

extension UserStatusFilterApi on UserStatusFilter {
  String get apiValue {
    switch (this) {
      case UserStatusFilter.all:
        return 'ALL';
      case UserStatusFilter.admin:
        return 'ADMIN';
      case UserStatusFilter.active:
        return 'ACTIVE';
      case UserStatusFilter.inactive:
        return 'INACTIVE';
    }
  }

  String get label {
    switch (this) {
      case UserStatusFilter.all:
        return 'All';
      case UserStatusFilter.admin:
        return 'Admins';
      case UserStatusFilter.active:
        return 'Active';
      case UserStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

enum UserSortBy { createdAt, name, email }

extension UserSortByApi on UserSortBy {
  String get apiValue {
    switch (this) {
      case UserSortBy.createdAt:
        return 'createdAt';
      case UserSortBy.name:
        return 'name';
      case UserSortBy.email:
        return 'email';
    }
  }

  String get label {
    switch (this) {
      case UserSortBy.createdAt:
        return 'Joined';
      case UserSortBy.name:
        return 'Name';
      case UserSortBy.email:
        return 'Email';
    }
  }
}

enum SortDir { asc, desc }

extension SortDirApi on SortDir {
  String get apiValue => this == SortDir.asc ? 'ASC' : 'DESC';
}
