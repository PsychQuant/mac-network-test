public enum TrafficRate {
    /// Mbps between two readings of a 32-bit interface byte counter.
    /// Wrapping subtraction absorbs one counter wrap, enough for intervals of a few seconds.
    public static func mbps(fromBytes: UInt32, toBytes: UInt32, seconds: Double) -> Double? {
        guard seconds > 0 else { return nil }
        return Double(toBytes &- fromBytes) * 8 / seconds / 1_000_000
    }
}
