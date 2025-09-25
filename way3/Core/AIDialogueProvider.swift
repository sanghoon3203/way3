// 📁 Core/AIDialogueProvider.swift - AI 대화 공급자 인터페이스
import Foundation

/// 간단한 AI 대화 샘플 구현
class AIDialogueProvider {
    static let shared = AIDialogueProvider()

    private init() {}

    /// 샘플 대화 생성
    func generateSampleDialogue(merchantName: String, context: String = "greeting") -> String {
        let greetings = [
            "\(merchantName): 어서 오세요! 무엇을 도와드릴까요?",
            "\(merchantName): 안녕하세요, 오늘은 어떤 물건을 찾으시나요?",
            "\(merchantName): 반갑습니다! 좋은 상품들이 많이 들어왔어요."
        ]

        let trading = [
            "\(merchantName): 이 가격이면 어떠세요?",
            "\(merchantName): 품질 좋은 물건입니다. 추천드려요!",
            "\(merchantName): 특별히 할인해드릴게요."
        ]

        let farewell = [
            "\(merchantName): 감사합니다! 또 오세요!",
            "\(merchantName): 좋은 거래였습니다.",
            "\(merchantName): 안전한 여행 되세요!"
        ]

        switch context {
        case "greeting":
            return greetings.randomElement() ?? greetings[0]
        case "trading":
            return trading.randomElement() ?? trading[0]
        case "farewell":
            return farewell.randomElement() ?? farewell[0]
        default:
            return greetings.randomElement() ?? greetings[0]
        }
    }

    /// 상황에 맞는 대화 생성
    func generateContextualDialogue(
        merchantName: String,
        playerName: String,
        situation: DialogueSituation,
        mood: DialogueMood = .neutral
    ) -> String {

        switch situation {
        case .firstMeeting:
            return "\(merchantName): 처음 뵙는 분이시네요, \(playerName)님! 저희 상점에 오신 걸 환영합니다."

        case .regularCustomer:
            let moodText = mood == .happy ? "기분 좋아 보이시네요!" : "오늘도 찾아주셔서 감사합니다."
            return "\(merchantName): \(playerName)님, 또 오셨군요! \(moodText)"

        case .negotiation:
            return mood == .friendly ?
                "\(merchantName): \(playerName)님이시니까 특별히 생각해보겠습니다." :
                "\(merchantName): 죄송하지만 이 가격이 최선입니다, \(playerName)님."

        case .completedTrade:
            return "\(merchantName): 좋은 거래였습니다, \(playerName)님! 다음에 또 뵙겠습니다."

        case .browsingOnly:
            return "\(merchantName): 천천히 구경하세요, \(playerName)님. 궁금한 게 있으면 언제든 말씀하세요."
        }
    }
}

// MARK: - 대화 관련 열거형
enum DialogueSituation {
    case firstMeeting      // 첫 만남
    case regularCustomer   // 단골 고객
    case negotiation       // 가격 협상
    case completedTrade    // 거래 완료
    case browsingOnly      // 둘러보기만
}

enum DialogueMood {
    case friendly      // 친근함
    case neutral       // 중립
    case happy         // 기쁨
    case serious       // 진지함
}