/// Runs a refresh at most once at a time.
///
/// A second pull while one is still in flight joins the running future
/// instead of starting another fetch. The refresh controls already ignore a
/// pull while their spinner is shown, but a screen can rebuild its scroll
/// view (empty state, error state, list) in the middle of a refresh, which
/// resets the control: the gate lives in the screen state and survives that.
class RefreshGate {
  Future<void>? _inFlight;

  /// Whether a refresh is currently running.
  bool get isRefreshing => _inFlight != null;

  Future<void> run(Future<void> Function() task) {
    final running = _inFlight;
    if (running != null) return running;
    late final Future<void> future;
    future = Future<void>.sync(task).whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return _inFlight = future;
  }
}
