abstract interface class DiagnosticsBackend {
  bool get isConfigured;

  Future<void> setCollectionEnabled(bool enabled);
}
