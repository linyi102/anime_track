import 'package:flutter/material.dart';

class OperationButton extends StatelessWidget {
  const OperationButton(
      {required this.text,
      this.onTap,
      this.active = true,
      this.horizontal = 30,
      this.height = 60,
      super.key});
  final void Function()? onTap;
  final String text;
  final bool active;
  final double horizontal;
  final double height;

  @override
  Widget build(BuildContext context) {
    // return SizedBox(
    //   height: 60,
    //   child: AspectRatio(
    //     aspectRatio: 18,
    //     child: Container(
    //       margin: EdgeInsets.symmetric(horizontal: horizontal, vertical: 10),
    //       child: OutlinedButton(
    //         onPressed: active ? onTap : null,
    //         child: Text(text),
    //       ),
    //     ),
    //   ),
    // );

    var borderRadius = BorderRadius.circular(50);

    return SizedBox(
      height: height,
      child: AspectRatio(
        aspectRatio: 6,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizontal, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
              borderRadius: borderRadius,
            ),
            child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: Center(
                    child: Text(text,
                        style: TextStyle(
                          color: active
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ))))),
      ),
    );
  }
}
