import Darwin

struct ByteCounters {
    let received: UInt32
    let sent: UInt32
}

/// Reads the link-level byte counters of one interface via getifaddrs.
/// The counters are 32-bit; TrafficRate.mbps handles a wrap between readings.
func readByteCounters(interface: String) -> ByteCounters? {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else { return nil }
    defer { freeifaddrs(head) }

    let link = sequence(first: first, next: { $0.pointee.ifa_next }).first { entry in
        entry.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK)
            && entry.pointee.ifa_data != nil
            && String(cString: entry.pointee.ifa_name) == interface
    }
    guard let data = link?.pointee.ifa_data?.assumingMemoryBound(to: if_data.self).pointee else { return nil }
    return ByteCounters(received: data.ifi_ibytes, sent: data.ifi_obytes)
}
