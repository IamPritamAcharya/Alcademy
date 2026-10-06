import 'package:flutter/material.dart';
import 'package:port/features/college_resources/data/document_repository.dart';
import 'package:port/features/college_resources/presentation/remote_document_page.dart';

class AcademicCalendarPage extends StatelessWidget {
  const AcademicCalendarPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const RemoteDocumentPage(document: DocumentDefinition.calendar);
}
