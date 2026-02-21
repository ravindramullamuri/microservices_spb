import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum UserType { patient, doctor }

class UserTypeSelector extends StatelessWidget {
  final UserType selectedType;
  final Function(UserType) onTypeSelected;

  const UserTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            context,
            'Patient',
            UserType.patient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTypeButton(
            context,
            'Clinician',
            UserType.doctor,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String title,
    UserType type,
  ) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
