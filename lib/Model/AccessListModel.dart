import 'package:flutter/material.dart';

class AccessListModel {
  final IconData icon;
  final String title;
  final String route;
  final dynamic arguments;
  AccessListModel({
    required this.icon,
    required this.title,
    required this.route,
    this.arguments,
  });
}
