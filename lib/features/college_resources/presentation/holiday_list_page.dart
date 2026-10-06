import 'package:flutter/material.dart';
import 'package:port/features/college_resources/data/document_repository.dart';
import 'package:port/features/college_resources/presentation/remote_document_page.dart';

class HolidayListPage extends StatelessWidget {
  const HolidayListPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const RemoteDocumentPage(document: DocumentDefinition.holidays);
}
