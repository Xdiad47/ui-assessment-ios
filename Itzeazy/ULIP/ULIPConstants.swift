import Foundation

// Relative paths on the Itzeazy backend's own ULIP gateway (AppEnvironment.current.baseURL + path).
// No separate ULIP login is needed anymore — every call is authenticated with the
// user's existing Itzeazy session token instead.
enum ULIPEndpoints {
    static let vehicleRC        = "ulip/vahan/04"
    static let chassisRC        = "ulip/vahan/05"
    static let engineRC         = "ulip/vahan/06"
    static let dlDetails        = "ulip/sarathi/01"
    static let challan          = "ulip/echallan/01"
    static let tgVehicle        = "ulip/tgvahan/01"
    static let tgDL             = "ulip/tgsarathi/01"
    static let evyatra          = "ulip/evyatra/01"
}
