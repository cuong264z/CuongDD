import 'package:flutter/material.dart';

import '../models/entities.dart';
import 'admin_home.dart';
import 'employee_dashboard.dart';
import 'manager_home.dart';

/// Chọn trang chủ theo vai trò (server cũng kiểm tra quyền ở từng API).
class RoleRouter {
  static Widget pageFor(String role) => switch (role) {
        Roles.admin => const AdminHome(),
        Roles.manager => const ManagerHome(),
        _ => const EmployeeDashboard(),
      };
}
