import Foundation

// MARK: - DocumentScannerFlowState
// Local screen-state machine for the 11-screen scan flow, scoped strictly to this feature —
// mirrors Android's SubScreen enum switched inside MainScreen.kt. Nothing else in this app uses a
// state-machine navigation pattern (every other feature chains NavigationLink/isActive instead),
// but an 11-screen flow with real branches (capture -> filter -> edit -> review -> {split |
// rearrange | esign | ocr | move-to-folder | view-pdf}) needs one; do NOT generalize this into an
// app-wide navigation abstraction.

enum DocumentScannerFlowState: Equatable {
    case list
    case camera
    case edit
    case filter
    case review
    case split
    case rearrange
    case eSign
    case ocr
    case moveToFolder
    case viewPdf
}
