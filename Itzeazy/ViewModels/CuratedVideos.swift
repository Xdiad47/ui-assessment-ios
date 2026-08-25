import Foundation

/// One hand-picked video shown in `VideoSearchView`'s top grid — title supplied by the business,
/// not derived from the API. `thumbnailUrl` is built directly from the video's own YouTube ID (no
/// local image asset, no extra network call), since every YouTube video has a predictable
/// thumbnail URL by ID — mirrors Android's `CuratedVideo` in `CuratedVideos.kt`.
struct CuratedVideo {
    let title: String
    let videoUrl: String

    var videoId: String? { extractYouTubeVideoId(from: videoUrl) }
    var thumbnailUrl: String {
        guard let videoId else { return "" }
        return "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"
    }
}

/// Static 6-video catalog per Video Tutorials category (RTO, Passport, Visa, ...) — keyed by the
/// same `query` string `VideoTutorialsGridView` passes for that category's live search.
/// Business-curated content, ported verbatim from Android's `CuratedVideos.kt`.
enum CuratedVideos {
    private static let catalog: [String: [CuratedVideo]] = [
        "RTO": [
            CuratedVideo(title: "Driving license Renewal", videoUrl: "https://youtu.be/ibqjiPuj4Gk"),
            CuratedVideo(title: "Learner Licence", videoUrl: "https://youtu.be/6EtcYKWLzLE"),
            CuratedVideo(title: "Vehicle Registration", videoUrl: "https://youtu.be/5p86bHkIyHA"),
            CuratedVideo(title: "RC Transfer Process", videoUrl: "https://youtu.be/-V-oICOJIQY"),
            CuratedVideo(title: "Ownership Change", videoUrl: "https://youtu.be/urPOenpFz2U"),
            CuratedVideo(title: "Driving Test Tips", videoUrl: "https://youtu.be/dr-rq-D6aC0")
        ],
        "Passport": [
            CuratedVideo(title: "Apply Passport", videoUrl: "https://youtu.be/mHbVyLd3cEk"),
            CuratedVideo(title: "Passport Renewal", videoUrl: "https://youtu.be/kfThLP8jzlc"),
            CuratedVideo(title: "Senior Citizens Passport", videoUrl: "https://youtu.be/mobP-ASGBnM"),
            CuratedVideo(title: "Documents Required", videoUrl: "https://youtu.be/LCOj3eIzwAM"),
            CuratedVideo(title: "Tatkal Passport", videoUrl: "https://youtu.be/5TKHuRqXZic"),
            CuratedVideo(title: "ECR Passport", videoUrl: "https://youtu.be/OSvp31nnmAs")
        ],
        "Visa": [
            CuratedVideo(title: "Apply Visa", videoUrl: "https://youtu.be/Ri_Ud4vlEtw"),
            CuratedVideo(title: "Visa Document Checklist", videoUrl: "https://youtu.be/815e3zsxPVA"),
            CuratedVideo(title: "Visa Appointment Booking", videoUrl: "https://youtu.be/1LtS3Q99YfE"),
            CuratedVideo(title: "Visa Interview Preparation", videoUrl: "https://youtu.be/c9CNWTYv9-A"),
            CuratedVideo(title: "Track Visa Status", videoUrl: "https://youtu.be/MH1V8SZTaQY"),
            CuratedVideo(title: "Visa Rejection & Reapply Guide", videoUrl: "https://youtu.be/omrBN_GeoV0")
        ],
        "Driving License": [
            CuratedVideo(title: "Driving Licence Renewal", videoUrl: "https://youtu.be/h47AUkSJ0JY"),
            CuratedVideo(title: "Learner Licence", videoUrl: "https://youtu.be/IPn2xxmidko"),
            CuratedVideo(title: "Vehicle Registration", videoUrl: "https://youtu.be/CjyQD3LJyh4"),
            CuratedVideo(title: "RC Transfer Process", videoUrl: "https://youtu.be/-V-oICOJIQY"),
            CuratedVideo(title: "Ownership Change", videoUrl: "https://youtu.be/urPOenpFz2U"),
            CuratedVideo(title: "Driving Test Tips", videoUrl: "https://youtu.be/JLVU1fUQZ1k")
        ],
        "Birth Certificate": [
            CuratedVideo(title: "Apply Birth Certificate", videoUrl: "https://youtu.be/BfU_vnPbU88"),
            CuratedVideo(title: "Required Documents", videoUrl: "https://youtu.be/eJzxBqg3KFs"),
            CuratedVideo(title: "Birth Registration Process", videoUrl: "https://youtu.be/0u5bVtkCTiM"),
            CuratedVideo(title: "Correct Birth Certificate", videoUrl: "https://youtu.be/0u5bVtkCTiM"),
            CuratedVideo(title: "Track Application Status", videoUrl: "https://youtu.be/4PPEchlq5og"),
            CuratedVideo(title: "Download Birth Certificate", videoUrl: "https://youtu.be/Do04SZiO7ZU")
        ],
        "Marriage Registration": [
            CuratedVideo(title: "Apply Marriage Registration", videoUrl: "https://youtu.be/Wqyb8RA_bWM"),
            CuratedVideo(title: "Required Documents", videoUrl: "https://youtu.be/pWhJSDXwNo0"),
            CuratedVideo(title: "Book Registration Appointment", videoUrl: "https://youtu.be/qjWM4y3S37k"),
            CuratedVideo(title: "Marriage Certificate Verification", videoUrl: "https://youtu.be/jw5QT2PINEI"),
            CuratedVideo(title: "Track Application Status", videoUrl: "https://youtu.be/QWjAsyjxSrQ"),
            CuratedVideo(title: "Download Marriage Certificate", videoUrl: "https://youtu.be/pWhJSDXwNo0")
        ],
        "PAN Card": [
            CuratedVideo(title: "Apply PAN Card", videoUrl: "https://youtu.be/etzqh2Vaeyw"),
            CuratedVideo(title: "PAN Card 10-Digit Number", videoUrl: "https://youtu.be/mdHJfjsAa1k"),
            CuratedVideo(title: "PAN and Aadhaar Update", videoUrl: "https://youtu.be/EHGEDOWz6Sk"),
            CuratedVideo(title: "Link PAN with Aadhaar", videoUrl: "https://youtu.be/TaeumJ_dit4"),
            CuratedVideo(title: "Track PAN Application Status", videoUrl: "https://youtu.be/ArlxtOfNekg"),
            CuratedVideo(title: "Download e-PAN Card", videoUrl: "https://youtu.be/ArlxtOfNekg")
        ],
        "Aadhaar Card": [
            CuratedVideo(title: "Apply Aadhaar Card", videoUrl: "https://youtu.be/8bWIdkcnVCw"),
            CuratedVideo(title: "Required Documents", videoUrl: "https://youtu.be/452HPZaS9LA"),
            CuratedVideo(title: "Book Aadhaar Appointment", videoUrl: "https://youtu.be/452HPZaS9LA"),
            CuratedVideo(title: "Update Aadhaar Details", videoUrl: "https://youtu.be/R_qCON5w5Wo"),
            CuratedVideo(title: "Update Aadhaar Card Photo", videoUrl: "https://youtu.be/bTyOA-eYKb8"),
            CuratedVideo(title: "Download e-Aadhaar Card", videoUrl: "https://youtu.be/Fmo7WAvnpWw")
        ]
    ]

    static func forCategory(_ query: String) -> [CuratedVideo] {
        catalog[query] ?? []
    }
}
