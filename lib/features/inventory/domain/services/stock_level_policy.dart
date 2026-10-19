enum StockLevel { empty, low, available }

/// Classifies the live inventory balance against the configured reorder point.
class StockLevelPolicy {
  static StockLevel classify({
    required double current,
    required double minimum,
  }) {
    if (current <= 0) return StockLevel.empty;
    if (minimum > 0 && current <= minimum) return StockLevel.low;
    return StockLevel.available;
  }
}
