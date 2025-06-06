import 'package:github_flutter/src/common.dart';

/// Superclass for all services.
abstract class Service {
  final GitHub github;

  const Service(this.github);
}
