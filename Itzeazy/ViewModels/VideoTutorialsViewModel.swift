import Foundation
import Combine

struct VideoTutorialItem: Identifiable {
    let id = UUID()
    let imageURL: String
}

class VideoTutorialsViewModel: ObservableObject {
    let pageTitle: String = "Video Tutorials"
    let sectionTitle: String = "Videos"
    let seeMoreTitle: String = "See More ON"

    let tutorials: [VideoTutorialItem] = [
        VideoTutorialItem(imageURL: "https://www.figma.com/api/mcp/asset/af608258-d681-4920-bceb-3707895dba26"),
        VideoTutorialItem(imageURL: "https://www.figma.com/api/mcp/asset/e2bcc9c1-fc0e-482b-8522-b1b13126537b"),
        VideoTutorialItem(imageURL: "https://www.figma.com/api/mcp/asset/e8dbbcb2-b610-4293-a692-f7e1ed01304d")
    ]
}
