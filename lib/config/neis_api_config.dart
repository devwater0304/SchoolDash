class NeisApiConfig {
  const NeisApiConfig({
    required this.apiKey,
    this.baseUri = 'https://open.neis.go.kr/hub',
  });

  const NeisApiConfig.fromEnvironment()
    : apiKey = const String.fromEnvironment('NEIS_API_KEY'),
      baseUri = 'https://open.neis.go.kr/hub';

  final String apiKey;
  final String baseUri;

  bool get isConfigured => apiKey.isNotEmpty;
}
