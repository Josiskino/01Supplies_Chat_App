import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calls_sign_out.g.dart';

/// Tears down the support calls session during an explicit sign-out.
///
/// Must complete *before* the main session token is cleared: ending the active
/// call, unregistering the push device and reporting the agent offline are
/// authenticated calls-service requests, and the calls session can only be
/// re-exchanged while the main token still exists.
abstract interface class CallsSignOut {
  Future<void> run();
}

class NoopCallsSignOut implements CallsSignOut {
  const NoopCallsSignOut();
  @override
  Future<void> run() async {}
}

/// Overridden by the calls host when support calls are configured.
@Riverpod(keepAlive: true)
CallsSignOut callsSignOut(Ref ref) => const NoopCallsSignOut();
