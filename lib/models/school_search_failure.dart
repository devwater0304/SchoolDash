enum SchoolSearchFailureType { notConfigured, network, invalidResponse, api }

class SchoolSearchFailure implements Exception {
  const SchoolSearchFailure(this.type, {this.message});

  final SchoolSearchFailureType type;
  final String? message;
}
