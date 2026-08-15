class SchoolLocationApiConfig {
  const SchoolLocationApiConfig({required this.apiKey, required this.baseUri});

  const SchoolLocationApiConfig.fromEnvironment()
    : apiKey = const String.fromEnvironment('SCHOOL_LOCATION_API_KEY'),
      baseUri = const String.fromEnvironment('SCHOOL_LOCATION_API_URL');

  final String apiKey;
  final String baseUri;

  bool get isConfigured =>
      apiKey.trim().isNotEmpty && baseUri.trim().isNotEmpty;
}
