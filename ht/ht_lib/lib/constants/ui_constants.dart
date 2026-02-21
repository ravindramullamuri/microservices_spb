import 'package:flutter/material.dart';

BoxDecoration boxDecoration() {
  return BoxDecoration(
    color: Colors.grey.shade50,
    border: Border.all(
      color: Colors.grey.shade300,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
deviceWidth(context)=> MediaQuery.of(context).size.width;
deviceHeight(context)=> MediaQuery.of(context).size.height;