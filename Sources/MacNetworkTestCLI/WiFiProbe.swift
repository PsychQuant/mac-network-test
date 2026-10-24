import CoreWLAN

/// Wi-Fi link facts that need no Location Services permission.
/// SSID and BSSID are deliberately not read: they reveal location.
struct WiFiLink {
    let interfaceName: String
    let rssiDBm: Int
    let noiseDBm: Int
    let transmitRateMbps: Double
    let phyMode: String
    let channel: Int
    let band: String
    let width: String
}

/// nil when there is no Wi-Fi interface or it is not associated.
func readWiFiLink() -> WiFiLink? {
    guard let iface = CWWiFiClient.shared().interface(),
          let name = iface.interfaceName,
          let channel = iface.wlanChannel(),
          iface.rssiValue() != 0
    else { return nil }
    return WiFiLink(
        interfaceName: name,
        rssiDBm: iface.rssiValue(),
        noiseDBm: iface.noiseMeasurement(),
        transmitRateMbps: iface.transmitRate(),
        phyMode: describe(iface.activePHYMode()),
        channel: channel.channelNumber,
        band: describe(channel.channelBand),
        width: describe(channel.channelWidth)
    )
}

private func describe(_ mode: CWPHYMode) -> String {
    switch mode {
    case .mode11a: "802.11a"
    case .mode11b: "802.11b"
    case .mode11g: "802.11g"
    case .mode11n: "802.11n"
    case .mode11ac: "802.11ac"
    case .mode11ax: "802.11ax"
    default: "802.11"
    }
}

private func describe(_ band: CWChannelBand) -> String {
    switch band {
    case .band2GHz: "2.4 GHz"
    case .band5GHz: "5 GHz"
    case .band6GHz: "6 GHz"
    default: "unknown band"
    }
}

private func describe(_ width: CWChannelWidth) -> String {
    switch width {
    case .width20MHz: "20 MHz"
    case .width40MHz: "40 MHz"
    case .width80MHz: "80 MHz"
    case .width160MHz: "160 MHz"
    default: "unknown width"
    }
}
