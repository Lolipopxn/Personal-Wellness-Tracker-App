import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  final Function(String?) onConfirm;
  const MoodSelector({Key? key, required this.onConfirm}) : super(key: key);

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  String? selectedMood;

  final List<String> moods = ["😃", "😊", "😐", "😢", "😠"];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("เลือกอารมณ์ของวันนี้"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            children: moods.map((emoji) {
              return ChoiceChip(
                label: Text(emoji, style: TextStyle(fontSize: 24)),
                selected: selectedMood == emoji,
                selectedColor: Colors.blue.shade100,
                backgroundColor: Colors.grey.shade200,
                onSelected: (_) {
                  setState(() {
                    selectedMood = emoji;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); 
          },
          child: Text("ยกเลิก"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(selectedMood);
            Navigator.pop(context);
          },
          child: Text("ตกลง"),
        ),
      ],
    );
  }
}
