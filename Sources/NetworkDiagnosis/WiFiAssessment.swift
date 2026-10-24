public enum WiFiAssessment {
    /// -67 dBm is the usual design floor for voice and video over Wi-Fi.
    public static let minimumRSSI = -67
    public static let minimumSNR = 25

    public static func isStrong(rssiDBm: Int, noiseDBm: Int) -> Bool {
        rssiDBm >= minimumRSSI && rssiDBm - noiseDBm >= minimumSNR
    }
}
