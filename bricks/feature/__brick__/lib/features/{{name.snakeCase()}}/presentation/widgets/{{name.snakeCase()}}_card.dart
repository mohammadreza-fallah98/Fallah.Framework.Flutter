import 'package:flutter/material.dart';

import '../../domain/entities/{{name.snakeCase()}}.dart';

class {{name.pascalCase()}}Card extends StatelessWidget {
  const {{name.pascalCase()}}Card({super.key, required this.item, this.onTap});

  final {{name.pascalCase()}} item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final owner = item.createdByName;
    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: owner == null ? null : Text(owner),
        onTap: onTap,
      ),
    );
  }
}
