import Foundation

enum ULIPEndpoints {
    static let login            = "/user/login"
    static let vehicleRC        = "/VAHAN/04"
    static let chassisRC        = "/VAHAN/05"
    static let engineRC         = "/VAHAN/06"
    static let dlDetails        = "/SARATHI/01"
    static let challan          = "/ECHALLAN/01"
    static let tgVehicle        = "/TGVAHAN/01"
    static let tgDL             = "/TGSARATHI/01"
    static let evyatra          = "/EVYATRA/01"
}

// Credentials are stored here for the client app.
// Do NOT expose these in logs or analytics.
enum ULIPCredentials {
    static let username = "ehqo_itzeazy_usr"
    static let password = "kL1z.TGr33"
}
