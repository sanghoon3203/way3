import Foundation

struct StoryChapter: Codable, Identifiable, Hashable {
    let id: String
    let chapter: Int
    let title: String
    let storyType: String
    let completed: Bool
    let summary: String?
    let entryNodeId: String?

    private enum CodingKeys: String, CodingKey {
        case id, chapter, title, storyType, completed, summary
        case entryNodeId
        case chapterId
        case entryNode
    }

    init(
        id: String,
        chapter: Int,
        title: String,
        storyType: String,
        completed: Bool,
        summary: String? = nil,
        entryNodeId: String? = nil
    ) {
        self.id = id
        self.chapter = chapter
        self.title = title
        self.storyType = storyType
        self.completed = completed
        self.summary = summary
        self.entryNodeId = entryNodeId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let explicitId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = explicitId
        } else if let chapterId = try container.decodeIfPresent(String.self, forKey: .chapterId) {
            id = chapterId
        } else {
            id = UUID().uuidString
        }
        chapter = try container.decodeIfPresent(Int.self, forKey: .chapter) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        storyType = try container.decodeIfPresent(String.self, forKey: .storyType) ?? "main"
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        entryNodeId = try container.decodeIfPresent(String.self, forKey: .entryNodeId)
            ?? container.decodeIfPresent(String.self, forKey: .entryNode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(chapter, forKey: .chapter)
        try container.encode(title, forKey: .title)
        try container.encode(storyType, forKey: .storyType)
        try container.encode(completed, forKey: .completed)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(entryNodeId, forKey: .entryNodeId)
    }
}

struct MerchantStoryChaptersData: Codable {
    let merchantId: String
    let chapters: [StoryChapter]
}

struct MerchantStoryChaptersResponse: Codable {
    let success: Bool
    let data: MerchantStoryChaptersData?
    let error: String?
}

struct ChapterRewardClaimRequest: Encodable {
    let chapterId: String
    let money: Int?
    let experience: Int?
    let keyItemName: String?
    let personalItemTemplateId: String?
}

struct ChapterRewardClaimResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
