/// Yields to the UI thread between heavy steps so low-RAM PCs stay responsive.
abstract final class ManagedLoader {
  static Future<void> breathe() => Future<void>.delayed(Duration.zero);

  static Future<List<T>> runSequential<T>(
    List<Future<T> Function()> steps,
  ) async {
    final results = <T>[];
    for (final step in steps) {
      await breathe();
      results.add(await step());
    }
    return results;
  }
}
