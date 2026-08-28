import SwiftUI

// MARK: - DocumentScannerView
// The flow host for the whole 11-screen Document Scanner feature — mirrors the DOCUMENT_SCANNER*
// branch of Android's MainScreen.kt, but scoped locally to this feature (see
// DocumentScannerFlowState). Owns every piece of state Android hoists at the MainScreen level:
// the in-progress scan session, which document a PDF tool (Split/Rearrange/e-Sign/OCR/Move to
// Folder) is targeting and where to return afterward, and which document is open for viewing.

struct DocumentScannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState

    @State private var flowState: DocumentScannerFlowState = .list

    @State private var scanSession: ScanSession?
    @State private var pdfToolDocument: ScannedDocument?
    @State private var pdfToolReturnState: DocumentScannerFlowState = .list
    @State private var openDocumentTarget: ScannedDocument?
    @State private var openDocumentUnlockedPath: String?
    @State private var viewPdfDocument: ScannedDocument?
    @State private var appendToDocumentId: String?
    @State private var scannerStartsOnFoldersTab = false
    /// The name of the derived document a Split/Rearrange/e-Sign operation just produced, so the
    /// Review screen it hands off to can announce it via toast — cleared on every OTHER path into
    /// `.review` (opening a document from the list, importing a PDF) so a stale name from an
    /// earlier, unrelated PDF-tool run can never get attached to a document it has nothing to do
    /// with.
    @State private var justSavedDocName: String?

    var body: some View {
        Group {
            switch flowState {
            case .list:
                DocumentScannerListView(
                    startOnFoldersTab: scannerStartsOnFoldersTab,
                    onStartScan: { flowState = .camera },
                    onOpenDocument: { doc, unlockedPath in
                        openDocumentTarget = doc
                        openDocumentUnlockedPath = unlockedPath
                        justSavedDocName = nil
                        flowState = .review
                    },
                    onSplitPdf: { doc in beginPdfTool(doc, target: .split, returnTo: .list) },
                    onRearrangePdf: { doc in beginPdfTool(doc, target: .rearrange, returnTo: .list) },
                    onESign: { doc in beginPdfTool(doc, target: .eSign, returnTo: .list) },
                    onOcr: { doc in beginPdfTool(doc, target: .ocr, returnTo: .list) },
                    onMoveToFolder: { doc in beginPdfTool(doc, target: .moveToFolder, returnTo: .list) },
                    onBack: { presentationMode.wrappedValue.dismiss() }
                )
                .onAppear { scannerStartsOnFoldersTab = false }

            case .camera:
                DocumentScannerCameraView(
                    onClose: { flowState = .list },
                    onProceed: { result in
                        scanSession = ScanSession(mode: result.mode, idSideOption: result.idSideOption, rawPages: result.pages, appendToDocumentId: appendToDocumentId)
                        appendToDocumentId = nil
                        flowState = .edit
                    }
                )

            case .edit:
                if let session = scanSession {
                    DocumentScannerEditView(
                        rawPages: session.rawPages,
                        onBack: { flowState = .camera },
                        onNext: { editedURLs in
                            scanSession?.editedPageURLs = editedURLs
                            flowState = .filter
                        }
                    )
                } else {
                    Color.clear.onAppear { flowState = .list }
                }

            case .filter:
                if let session = scanSession {
                    DocumentScannerFilterView(
                        pageURLs: session.editedPageURLs,
                        onBack: { flowState = .edit },
                        onNext: { filteredURLs in
                            scanSession?.filteredPageURLs = filteredURLs
                            flowState = .review
                        }
                    )
                } else {
                    Color.clear.onAppear { flowState = .list }
                }

            case .review:
                if let session = scanSession {
                    DocumentScannerReviewView(
                        session: session,
                        existingDocumentId: nil,
                        unlockedPdfPath: nil,
                        onBack: { scanSession = nil; flowState = .list },
                        onDeleted: { scanSession = nil; flowState = .list },
                        onAddMore: { doc in
                            appendToDocumentId = doc.id
                            scanSession = nil
                            flowState = .camera
                        },
                        onSplitPdf: { doc in beginPdfTool(doc, target: .split, returnTo: .review) },
                        onRearrangePdf: { doc in beginPdfTool(doc, target: .rearrange, returnTo: .review) },
                        onESign: { doc in beginPdfTool(doc, target: .eSign, returnTo: .review) },
                        onOcr: { doc in beginPdfTool(doc, target: .ocr, returnTo: .review) },
                        onMoveToFolder: { doc in beginPdfTool(doc, target: .moveToFolder, returnTo: .review) },
                        onViewPdf: { doc in viewPdfDocument = doc; flowState = .viewPdf },
                        onImportedPdf: { doc in
                            scanSession = nil
                            openDocumentTarget = doc
                            openDocumentUnlockedPath = nil
                            justSavedDocName = nil
                            flowState = .review
                        },
                        onFromFolder: {
                            scannerStartsOnFoldersTab = true
                            flowState = .list
                        },
                        justSavedDocName: $justSavedDocName
                    )
                } else if let existingDoc = openDocumentTarget {
                    DocumentScannerReviewView(
                        session: nil,
                        existingDocumentId: existingDoc.id,
                        unlockedPdfPath: openDocumentUnlockedPath,
                        onBack: { openDocumentTarget = nil; openDocumentUnlockedPath = nil; flowState = .list },
                        onDeleted: { openDocumentTarget = nil; openDocumentUnlockedPath = nil; flowState = .list },
                        onAddMore: { doc in
                            appendToDocumentId = doc.id
                            openDocumentTarget = nil
                            openDocumentUnlockedPath = nil
                            flowState = .camera
                        },
                        onSplitPdf: { doc in beginPdfTool(doc, target: .split, returnTo: .review) },
                        onRearrangePdf: { doc in beginPdfTool(doc, target: .rearrange, returnTo: .review) },
                        onESign: { doc in beginPdfTool(doc, target: .eSign, returnTo: .review) },
                        onOcr: { doc in beginPdfTool(doc, target: .ocr, returnTo: .review) },
                        onMoveToFolder: { doc in beginPdfTool(doc, target: .moveToFolder, returnTo: .review) },
                        onViewPdf: { doc in viewPdfDocument = doc; flowState = .viewPdf },
                        onImportedPdf: { doc in
                            openDocumentTarget = doc
                            openDocumentUnlockedPath = nil
                            justSavedDocName = nil
                            flowState = .review
                        },
                        onFromFolder: {
                            scannerStartsOnFoldersTab = true
                            flowState = .list
                        },
                        justSavedDocName: $justSavedDocName
                    )
                } else {
                    Color.clear.onAppear { flowState = .list }
                }

            case .split:
                if let doc = pdfToolDocument {
                    DocumentScannerSplitView(
                        document: doc,
                        onBack: { pdfToolDocument = nil; flowState = pdfToolReturnState },
                        onSplitComplete: { newDoc in
                            pdfToolDocument = nil
                            scanSession = nil
                            openDocumentTarget = newDoc
                            openDocumentUnlockedPath = nil
                            justSavedDocName = newDoc.name
                            flowState = .review
                        }
                    )
                } else {
                    Color.clear.onAppear { flowState = pdfToolReturnState }
                }

            case .rearrange:
                if let doc = pdfToolDocument {
                    DocumentScannerRearrangeView(
                        document: doc,
                        onBack: { pdfToolDocument = nil; flowState = pdfToolReturnState },
                        onRearrangeComplete: { newDoc in
                            pdfToolDocument = nil
                            scanSession = nil
                            openDocumentTarget = newDoc
                            openDocumentUnlockedPath = nil
                            justSavedDocName = newDoc.name
                            flowState = .review
                        }
                    )
                } else {
                    Color.clear.onAppear { flowState = pdfToolReturnState }
                }

            case .eSign:
                if let doc = pdfToolDocument {
                    DocumentScannerESignView(
                        document: doc,
                        onBack: { pdfToolDocument = nil; flowState = pdfToolReturnState },
                        onSaveComplete: { newDoc in
                            pdfToolDocument = nil
                            scanSession = nil
                            openDocumentTarget = newDoc
                            openDocumentUnlockedPath = nil
                            justSavedDocName = newDoc.name
                            flowState = .review
                        }
                    )
                } else {
                    Color.clear.onAppear { flowState = pdfToolReturnState }
                }

            case .ocr:
                if let doc = pdfToolDocument {
                    DocumentScannerOCRView(
                        document: doc,
                        onBack: { pdfToolDocument = nil; flowState = pdfToolReturnState }
                    )
                } else {
                    Color.clear.onAppear { flowState = pdfToolReturnState }
                }

            case .moveToFolder:
                if let doc = pdfToolDocument {
                    DocumentScannerMoveToFolderView(
                        document: doc,
                        onBack: { pdfToolDocument = nil; flowState = pdfToolReturnState },
                        onMoved: { pdfToolDocument = nil; flowState = pdfToolReturnState }
                    )
                } else {
                    Color.clear.onAppear { flowState = pdfToolReturnState }
                }

            case .viewPdf:
                if let doc = viewPdfDocument {
                    DocumentScannerViewPdfView(
                        document: doc,
                        onBack: { viewPdfDocument = nil; flowState = .review },
                        onSplitPdf: { d in beginPdfTool(d, target: .split, returnTo: .viewPdf) },
                        onRearrangePdf: { d in beginPdfTool(d, target: .rearrange, returnTo: .viewPdf) },
                        onESign: { d in beginPdfTool(d, target: .eSign, returnTo: .viewPdf) },
                        onOcr: { d in beginPdfTool(d, target: .ocr, returnTo: .viewPdf) }
                    )
                } else {
                    Color.clear.onAppear { flowState = .review }
                }
            }
        }
        .onAppear { updateTabBarVisibility() }
        .onChange(of: flowState) { _, _ in updateTabBarVisibility() }
        .onDisappear { tabBarState.isHidden = false }
    }

    private func beginPdfTool(_ document: ScannedDocument, target: DocumentScannerFlowState, returnTo: DocumentScannerFlowState) {
        pdfToolDocument = document
        pdfToolReturnState = returnTo
        flowState = target
    }

    /// The custom tab bar only belongs on the entry screens — the document/folder list and the
    /// Document Scan / ID Scan mode picker. Every screen from Edit onward is a focused, full-screen
    /// task (capture -> edit -> filter -> review -> PDF tools), so it's hidden there and restored
    /// the moment the user is back on an entry screen — mirrors YoutubePlayerView's hide/restore
    /// convention, just centralized here since this flow host owns every state transition.
    private func updateTabBarVisibility() {
        tabBarState.isHidden = flowState != .list && flowState != .camera
    }
}

#Preview {
    NavigationView { DocumentScannerView() }
        .environmentObject(TabBarState())
}
