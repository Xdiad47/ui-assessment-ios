import UIKit

// MARK: - PhotoSheetPrintRenderer
// Mirrors Android's PhotoSheetPrintDocumentAdapter.drawTiledSheet: tiles the current photo
// across whatever page size the OS print dialog settles on, centered, with a light-gray cut
// guide around each tile. Layout is computed fresh per page from the real content rect, not
// fixed in advance — same as the Android version.

final class PhotoSheetPrintRenderer: UIPrintPageRenderer {
    private let image: UIImage
    private let tileWidthMm: CGFloat
    private let tileHeightMm: CGFloat

    init(image: UIImage, tileWidthMm: CGFloat, tileHeightMm: CGFloat) {
        self.image = image
        self.tileWidthMm = tileWidthMm
        self.tileHeightMm = tileHeightMm
        super.init()
    }

    override var numberOfPages: Int { 1 }

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        func mmToPt(_ mm: CGFloat) -> CGFloat { mm / 25.4 * 72.0 }

        let tileWidth = mmToPt(tileWidthMm)
        let tileHeight = mmToPt(tileHeightMm)
        let gap = mmToPt(2)
        guard tileWidth > 0, tileHeight > 0, let context = UIGraphicsGetCurrentContext() else { return }

        let columns = max(1, Int(floor((contentRect.width + gap) / (tileWidth + gap))))
        let rows = max(1, Int(floor((contentRect.height + gap) / (tileHeight + gap))))

        let gridWidth = CGFloat(columns) * tileWidth + CGFloat(columns - 1) * gap
        let gridHeight = CGFloat(rows) * tileHeight + CGFloat(rows - 1) * gap
        let startX = contentRect.minX + (contentRect.width - gridWidth) / 2
        let startY = contentRect.minY + (contentRect.height - gridHeight) / 2

        for row in 0..<rows {
            for col in 0..<columns {
                let x = startX + CGFloat(col) * (tileWidth + gap)
                let y = startY + CGFloat(row) * (tileHeight + gap)
                let destRect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
                image.draw(in: destRect)
                context.setStrokeColor(UIColor.lightGray.cgColor)
                context.setLineWidth(1)
                context.stroke(destRect)
            }
        }
    }
}
