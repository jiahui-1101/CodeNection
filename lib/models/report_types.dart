import 'package:flutter/material.dart';

/*// 所有 report 类型定义（共用）
final List<Map<String, dynamic>> reportTypes = [
  {
    'title': 'Facility Issue',
    'icon': Icons.home_repair_service,
    'description': 'Report problems with campus facilities',
  },
  {
    'title': 'Safety Concern',
    'icon': Icons.security,
    'description': 'Report safety or security issues',
  },
  {
    'title': 'IT Problem',
    'icon': Icons.computer,
    'description': 'Report technology or network issues',
  },
  {
    'title': 'Maintenance Request',
    'icon': Icons.construction,
    'description': 'Request maintenance services',
  },
];*/

//report categories/TYPES (must match keys in ReportPage's _categoryToDepartmentMap)
final List<Map<String, dynamic>> reportTypes = [
  {
    'title': 'Damage', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.home_repair_service,
    'description': 'Report problems with campus facilities',
  },
  {
    'title': 'Security Threat', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.security,
    'description': 'Report safety or security issues',
  },
  {
    'title': 'Cleanliness', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.cleaning_services, // 更合适的图标
    'description': 'Report cleanliness issues',
  },
  {
    'title': 'Blocked Pathway', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.block,
    'description': 'Report blocked pathways or accessibility issues',
  },
  {
    'title': 'IT Problem', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.computer,
    'description': 'Report technology or network issues',
  },
  {
    'title': 'Academic Related', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.school,
    'description': 'Report academic related issues',
  },
  {
    'title': 'Student Services', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.people,
    'description': 'Report student services related issues',
  },
  {
    'title': 'Others', // ✅ 确保这里与 ReportPage 中的 _categoryToDepartmentMap 键一致
    'icon': Icons.category,
    'description': 'Report other miscellaneous issues',
  },
];