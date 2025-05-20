class UserAccess {
  // Role IDs based on API response
  static const int admin = 1;
  static const int partner = 2;
  static const int seniorEngineer = 3;
  static const int juniorEngineer = 4;
  static const int teamMember = 5;
  static const int assistant = 6;
  static const int salesAndMarketing = 7;
  static const int accountTeam = 8;

  // Role Names
  static const String adminRole = 'Admin';
  static const String partnerRole = 'Partner';
  static const String seniorEngineerRole = 'Sr. Engineer';
  static const String juniorEngineerRole = 'Jr. Engineer';
  static const String teamMemberRole = 'Team member';
  static const String assistantRole = 'Assistance (Helper)';
  static const String salesAndMarketingRole = 'Sales and Marketing';
  static const String accountTeamRole = 'Account team';

  // Access Levels
  // Admin level access (can manage everything)
  static const List<int> adminAccess = [admin];
  
  // Partner level access (can manage most things except admin)
  static const List<int> partnerAccess = [admin, partner];
  
  // Senior Engineer level access (can manage junior roles)
  static const List<int> seniorEngineerAccess = [admin, partner, seniorEngineer];
  
  // Junior Engineer level access (can manage team members and below)
  static const List<int> juniorEngineerAccess = [admin, partner, seniorEngineer, juniorEngineer];
  
  // Team Member level access (can manage assistants)
  static const List<int> teamMemberAccess = [admin, partner, seniorEngineer, juniorEngineer, teamMember];
  
  // Assistant level access (can only manage other assistants)
  static const List<int> assistantAccess = [admin, partner, seniorEngineer, juniorEngineer, teamMember, assistant];

  // Helper Methods
  static String getRoleName(int designationId) {
    switch (designationId) {
      case admin:
        return adminRole;
      case partner:
        return partnerRole;
      case seniorEngineer:
        return seniorEngineerRole;
      case juniorEngineer:
        return juniorEngineerRole;
      case teamMember:
        return teamMemberRole;
      case assistant:
        return assistantRole;
      case salesAndMarketing:
        return salesAndMarketingRole;
      case accountTeam:
        return accountTeamRole;
      default:
        return 'Unknown Role';
    }
  }

  // Access Check Methods
  static bool hasAdminAccess(int? designationId) {
    return designationId != null && adminAccess.contains(designationId);
  }

  static bool hasPartnerAccess(int? designationId) {
    return designationId != null && partnerAccess.contains(designationId);
  }

  static bool hasSeniorEngineerAccess(int? designationId) {
    return designationId != null && seniorEngineerAccess.contains(designationId);
  }

  static bool hasJuniorEngineerAccess(int? designationId) {
    return designationId != null && juniorEngineerAccess.contains(designationId);
  }

  static bool hasTeamMemberAccess(int? designationId) {
    return designationId != null && teamMemberAccess.contains(designationId);
  }

  static bool hasAssistantAccess(int? designationId) {
    return designationId != null && assistantAccess.contains(designationId);
  }

  // Can Manage Check Methods
  static bool canManageUser(int? managerDesignationId, int? userDesignationId) {
    if (managerDesignationId == null || userDesignationId == null) return false;

    // Admin can manage everyone
    if (managerDesignationId == admin) return true;

    // Partner can manage everyone except admin
    if (managerDesignationId == partner) return userDesignationId != admin;

    // Senior Engineer can manage junior roles
    if (managerDesignationId == seniorEngineer) {
      return [juniorEngineer, teamMember, assistant].contains(userDesignationId);
    }

    // Junior Engineer can manage team members and assistants
    if (managerDesignationId == juniorEngineer) {
      return [teamMember, assistant].contains(userDesignationId);
    }

    // Team Member can manage assistants
    if (managerDesignationId == teamMember) {
      return userDesignationId == assistant;
    }

    // Assistant, Sales and Marketing, Account Team cannot manage anyone
    if ([assistant, salesAndMarketing, accountTeam].contains(managerDesignationId)) {
      return false;
    }

    // Default: no access
    return false;
  }

  // Get all roles for dropdown or selection
  static List<Map<String, dynamic>> getAllRoles() {
    return [
      {'id': admin, 'name': adminRole},
      {'id': partner, 'name': partnerRole},
      {'id': seniorEngineer, 'name': seniorEngineerRole},
      {'id': juniorEngineer, 'name': juniorEngineerRole},
      {'id': teamMember, 'name': teamMemberRole},
      {'id': assistant, 'name': assistantRole},
      {'id': salesAndMarketing, 'name': salesAndMarketingRole},
      {'id': accountTeam, 'name': accountTeamRole},
    ];
  }

  static bool isBelow(int? managerDesignationId, int? userDesignationId) {
    if (managerDesignationId == null || userDesignationId == null) return false;
    // Define the hierarchy order
    final hierarchy = [
      admin,
      partner,
      seniorEngineer,
      juniorEngineer,
      teamMember,
      assistant,
      salesAndMarketing,
      accountTeam,
    ];
    final managerIndex = hierarchy.indexOf(managerDesignationId);
    final userIndex = hierarchy.indexOf(userDesignationId);
    return userIndex > managerIndex;
  }
} 