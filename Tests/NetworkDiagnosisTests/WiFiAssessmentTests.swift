import Testing
@testable import NetworkDiagnosis

struct WiFiAssessmentTests {
    @Test(arguments: [
        (rssi: -34, noise: -95, strong: true),   // excellent signal, quiet channel
        (rssi: -67, noise: -95, strong: true),   // at the -67 dBm threshold
        (rssi: -72, noise: -95, strong: false),  // signal too weak
        (rssi: -60, noise: -75, strong: false),  // signal fine but SNR only 15 dB
    ])
    func `Classifies link strength by signal and SNR`(rssi: Int, noise: Int, strong: Bool) {
        #expect(WiFiAssessment.isStrong(rssiDBm: rssi, noiseDBm: noise) == strong)
    }
}
