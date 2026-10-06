enum PrivateCategory {
  photos('photos', 'private_photos'),
  videos('videos', 'private_videos'),
  documents('documents', 'private_documents'),
  notes('notes', 'private_notes');

  final String folder;
  final String preferencesKey;
  const PrivateCategory(this.folder, this.preferencesKey);
}
