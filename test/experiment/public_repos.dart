import 'package:github_flutter/github.dart';

void main() {
  final github = GitHub();

  github.repositories
      .listPublicRepositories(limit: 50)
      .listen((repo) {
        print('-> ${repo.fullName}');
      })
      .onDone(github.dispose);
}
