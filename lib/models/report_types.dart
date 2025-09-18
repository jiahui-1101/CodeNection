import 'package:flutter/material.dart';

//report_management_page de categories/TYPES (must match keys in ReportPage's _categoryToDepartmentMap)
final List<Map<String, dynamic>> reportTypes = [
  {
    'title': 'Damage', 
    'icon': Icons.home_repair_service,
    'description': 'Report problems with campus facilities',
  },
  {
    'title': 'Security Threat', 
    'icon': Icons.security,
    'description': 'Report safety or security issues',
  },
  {
    'title': 'Cleanliness', 
    'icon': Icons.cleaning_services, 
    'description': 'Report cleanliness issues',
  },
  {
    'title': 'Blocked Pathway', 
    'icon': Icons.block,
    'description': 'Report blocked pathways or accessibility issues',
  },
  {
    'title': 'IT Problem', 
    'icon': Icons.computer,
    'description': 'Report technology or network issues',
  },
  {
    'title': 'Academic Related', 
    'icon': Icons.school,
    'description': 'Report academic related issues',
  },
  {
    'title': 'Student Services',
    'icon': Icons.people,
    'description': 'Report student services related issues',
  },
  {
    'title': 'Others', 
    'icon': Icons.category,
    'description': 'Report other miscellaneous issues',
  },
];