import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Surveille la connectivité réseau.
///
/// `connectivity_plus` indique seulement qu'une interface est active — pas
/// qu'Internet est joignable (portail captif, Wi-Fi sans route). On complète
/// donc par une résolution DNS réelle.
class NetworkConnectivity {
  NetworkConnectivity._();

  static final _instance = NetworkConnectivity._();
  static NetworkConnectivity get instance => _instance;

  final _networkConnectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  /// Émet `true` quand Internet est réellement joignable.
  Stream<bool> get onStatusChange => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialise() async {
    await _checkStatus();
    _subscription = _networkConnectivity.onConnectivityChanged.listen((_) {
      _checkStatus();
    });
  }

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<void> _checkStatus() async {
    if (_controller.isClosed) return;
    _controller.sink.add(await isOnline());
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
