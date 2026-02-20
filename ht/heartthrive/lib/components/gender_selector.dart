import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../theme/app_theme.dart';

class GenderCardSelector extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? selectedValue;
  const GenderCardSelector({super.key, required this.onChanged,this.selectedValue});

  @override
  State<GenderCardSelector> createState() => _GenderCardSelectorState();
}

class _GenderCardSelectorState extends State<GenderCardSelector> {
  late String selectedGender = widget.selectedValue??"";

  @override
  void initState() {
    super.initState();

    // Notify parent of default value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(widget.selectedValue != null){
        widget.onChanged(widget.selectedValue!);
      }else{
        widget.onChanged(selectedGender);
      }

    });
  }

  void updateGender(){
    setState(() {
      selectedGender = widget.selectedValue!;
    });
  }

  Widget buildCard(String gender, IconData icon) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() => selectedGender = gender);
        widget.onChanged(gender);
      },
      child: Card(
        color:isSelected ? AppTheme.primaryColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8,),
              Text(gender, style: TextStyle(
                fontSize:deviceWidth(context) > 750 ?20: deviceWidth(context) > 410 ?14:deviceWidth(context) > 360 ?11:10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              )),
              const SizedBox(width: 2),
              gender == "Other" ?Image.asset("lib/assets/other_gender_logo.png",height:deviceWidth(context) > 360 ? 18: 12,color: isSelected ? Colors.white : Colors.black) :Icon(icon, size: deviceWidth(context) > 360 ? 24: 18, color: isSelected ? Colors.white : Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: buildCard("Male", Icons.male)),
            const SizedBox(width: 8),
            Expanded(child: buildCard("Female", Icons.female)),
            const SizedBox(width: 8),
            Expanded(child: buildCard("Other", Icons.transgender)),
          ],
        )
      ],
    );
  }
}

