/// Tolerant extraction of the order linked to a support ticket.
///
/// On `origin/develop` the messaging service only serializes `orderId` (the
/// Mongo id of the order) on a ticket. The human number customers see
/// (`Order.orderNumber`, e.g. `01-ORD 1731…`) lives in the order service and
/// is not projected into the ticket yet. Every shape a future projection is
/// likely to use is accepted here so the UI lights up without an app update,
/// and a raw Mongo id is never presented as an order number.
abstract final class OrderReferenceParser {
  static final RegExp _objectId = RegExp(r'^[0-9a-fA-F]{24}$');

  /// Human order number, or `null` when the payload only carries an id.
  static String? orderNumber(Map<String, dynamic> json) {
    final order = json['order'];
    final metadata = json['metadata'];
    final candidates = <Object?>[
      json['orderNumber'],
      json['orderReference'],
      if (order is Map) ...[
        order['orderNumber'],
        order['number'],
        order['reference'],
      ],
      if (metadata is Map) ...[
        metadata['orderNumber'],
        metadata['orderReference'],
      ],
    ];
    for (final candidate in candidates) {
      final value = _human(candidate);
      if (value != null) return value;
    }
    return null;
  }

  /// Technical id of the linked order, kept for a future lookup.
  static String? orderId(Map<String, dynamic> json) {
    final raw = json['orderId'];
    final order = json['order'];
    final value = raw is Map
        ? (raw['id'] ?? raw['_id'])
        : (raw ?? (order is Map ? (order['id'] ?? order['_id']) : null));
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _human(Object? value) {
    if (value is! String && value is! num) return null;
    final text = value.toString().trim();
    if (text.isEmpty || _objectId.hasMatch(text)) return null;
    return text;
  }
}
