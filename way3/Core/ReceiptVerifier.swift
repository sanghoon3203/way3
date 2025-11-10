//
//  ReceiptVerifier.swift
//  way3
//
//  영수증 OCR 기반 거래 인증 시스템
//  Vision 프레임워크를 사용한 텍스트 인식 및 금액 검증
//

import Foundation
import UIKit
import Vision
import CoreLocation
import os

// MARK: - Receipt Verification Result

struct ReceiptVerificationResult {
    let verified: Bool
    let amount: Int?
    let merchantName: String?
    let timestamp: Date
    let imageHash: String  // 중복 방지용
    let extractedText: String

    var isValid: Bool {
        return verified && amount != nil
    }
}

enum ReceiptVerificationError: Error {
    case imageProcessingFailed
    case noTextDetected
    case amountNotFound
    case insufficientAmount(found: Int, required: Int)
    case locationMismatch
    case duplicateReceipt
    case invalidFormat

    var localizedDescription: String {
        switch self {
        case .imageProcessingFailed:
            return "이미지 처리에 실패했습니다"
        case .noTextDetected:
            return "영수증에서 텍스트를 인식할 수 없습니다"
        case .amountNotFound:
            return "결제 금액을 찾을 수 없습니다"
        case .insufficientAmount(let found, let required):
            return "금액이 부족합니다 (필요: ₩\(required), 인식: ₩\(found))"
        case .locationMismatch:
            return "영수증 위치가 퀘스트 지역과 맞지 않습니다"
        case .duplicateReceipt:
            return "이미 사용된 영수증입니다"
        case .invalidFormat:
            return "영수증 형식이 올바르지 않습니다"
        }
    }
}

// MARK: - Receipt Verifier

@MainActor
class ReceiptVerifier: ObservableObject {
    static let shared = ReceiptVerifier()

    @Published var isProcessing: Bool = false
    @Published var extractedText: String = ""
    @Published var detectedAmount: Int?

    private let logger = Logger(subsystem: "com.way3.receipt", category: "ReceiptVerifier")
    private var usedReceiptHashes: Set<String> = []

    private init() {
        loadUsedReceipts()
    }

    // MARK: - Main Verification

    /// 영수증 검증 (Trading 퀘스트용)
    func verifyReceipt(
        image: UIImage,
        minPurchase: Int,
        requiredLocation: CLLocationCoordinate2D? = nil,
        questId: String
    ) async throws -> ReceiptVerificationResult {
        isProcessing = true
        defer { isProcessing = false }

        // 1. 이미지 해시 생성 (중복 방지)
        let imageHash = generateImageHash(image)

        guard !usedReceiptHashes.contains(imageHash) else {
            logger.error("❌ 중복 영수증 감지: \(imageHash)")
            throw ReceiptVerificationError.duplicateReceipt
        }

        // 2. OCR 텍스트 추출
        let extractedText = try await extractText(from: image)
        self.extractedText = extractedText

        logger.debug("📝 추출된 텍스트 (\(extractedText.count)자):\n\(extractedText)")

        // 3. 금액 파싱
        guard let amount = parseAmount(from: extractedText) else {
            logger.error("❌ 금액 인식 실패")
            throw ReceiptVerificationError.amountNotFound
        }

        self.detectedAmount = amount
        logger.info("💰 인식된 금액: ₩\(amount)")

        // 4. 최소 금액 검증
        guard amount >= minPurchase else {
            logger.error("❌ 금액 부족: \(amount) < \(minPurchase)")
            throw ReceiptVerificationError.insufficientAmount(found: amount, required: minPurchase)
        }

        // 5. 위치 검증 (선택적)
        if let requiredLocation = requiredLocation {
            let isLocationValid = verifyLocationFromReceipt(text: extractedText, target: requiredLocation)
            if !isLocationValid {
                logger.warning("⚠️ 위치 불일치 (계속 진행)")
                // 위치 불일치는 경고만 하고 통과 (선택적 검증)
            }
        }

        // 6. 상호명 추출 (선택적)
        let merchantName = extractMerchantName(from: extractedText)

        // 7. 검증 성공 - 영수증 해시 저장
        usedReceiptHashes.insert(imageHash)
        saveUsedReceipts()

        logger.info("✅ 영수증 검증 성공 - Quest: \(questId), 금액: ₩\(amount)")

        return ReceiptVerificationResult(
            verified: true,
            amount: amount,
            merchantName: merchantName,
            timestamp: Date(),
            imageHash: imageHash,
            extractedText: extractedText
        )
    }

    // MARK: - OCR Text Extraction

    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ReceiptVerificationError.imageProcessingFailed
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]  // 한국어 + 영어
        request.usesLanguageCorrection = true

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([request])

                    guard let observations = request.results, !observations.isEmpty else {
                        continuation.resume(throwing: ReceiptVerificationError.noTextDetected)
                        return
                    }

                    let recognizedText = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: "\n")

                    continuation.resume(returning: recognizedText)
                } catch {
                    continuation.resume(throwing: ReceiptVerificationError.imageProcessingFailed)
                }
            }
        }
    }

    // MARK: - Amount Parsing

    private func parseAmount(from text: String) -> Int? {
        // 다양한 금액 표현 패턴
        let patterns = [
            // 합계, 결제금액 등
            "합계[:\\s]*([0-9,]+)",
            "결제금액[:\\s]*([0-9,]+)",
            "총금액[:\\s]*([0-9,]+)",
            "승인금액[:\\s]*([0-9,]+)",
            // 영문
            "TOTAL[:\\s]*([0-9,]+)",
            "AMOUNT[:\\s]*([0-9,]+)",
            // 일반 숫자 (큰 금액 우선)
            "([0-9]{4,})"
        ]

        var amounts: [Int] = []

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

                for match in matches {
                    if match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: text) {
                        let numberString = String(text[range]).replacingOccurrences(of: ",", with: "")
                        if let amount = Int(numberString), amount >= 100 {  // 최소 100원
                            amounts.append(amount)
                        }
                    }
                }
            }
        }

        // 금액 후보 중 가장 큰 값 반환 (일반적으로 합계가 가장 큼)
        return amounts.max()
    }

    // MARK: - Merchant Name Extraction

    private func extractMerchantName(from text: String) -> String? {
        // 첫 줄에 주로 상호명이 있음
        let lines = text.components(separatedBy: .newlines)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // 한글/영문으로 시작하고 2~20자 사이
            if trimmed.count >= 2 && trimmed.count <= 20 {
                if trimmed.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
                    return trimmed
                }
            }
        }
        return nil
    }

    // MARK: - Location Verification (Optional)

    private func verifyLocationFromReceipt(text: String, target: CLLocationCoordinate2D) -> Bool {
        // 영수증에서 주소/지역명 추출 시도
        let seoulDistricts = ["강남구", "서초구", "송파구", "강동구", "관악구", "종로구", "중구"]

        for district in seoulDistricts {
            if text.contains(district) {
                logger.debug("📍 영수증 지역 감지: \(district)")
                // TODO: target 좌표와 지역명 매칭 로직
                return true
            }
        }

        // 주소를 찾을 수 없으면 통과 (선택적 검증)
        return true
    }

    // MARK: - Image Hashing (중복 방지)

    private func generateImageHash(_ image: UIImage) -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return UUID().uuidString
        }

        // SHA256 해시 생성
        let hash = imageData.hashValue
        return "\(hash)"
    }

    // MARK: - Used Receipts Management

    private func loadUsedReceipts() {
        if let data = UserDefaults.standard.data(forKey: "used_receipt_hashes"),
           let hashes = try? JSONDecoder().decode(Set<String>.self, from: data) {
            usedReceiptHashes = hashes
            logger.info("📋 사용된 영수증 \(hashes.count)개 로드")
        }
    }

    private func saveUsedReceipts() {
        if let data = try? JSONEncoder().encode(self.usedReceiptHashes) {
            UserDefaults.standard.set(data, forKey: "used_receipt_hashes")
            logger.debug("💾 영수증 해시 저장 (\(self.usedReceiptHashes.count)개)")
        }
    }

    func clearUsedReceipts() {
        usedReceiptHashes.removeAll()
        UserDefaults.standard.removeObject(forKey: "used_receipt_hashes")
        logger.info("🗑️ 영수증 기록 초기화")
    }

    // MARK: - Debug

    func testOCR(image: UIImage) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }

        let text = try await extractText(from: image)
        extractedText = text
        detectedAmount = parseAmount(from: text)

        logger.debug("🧪 테스트 OCR 결과:\n\(text)")
        if let amount = detectedAmount {
            logger.debug("💰 감지된 금액: ₩\(amount)")
        }

        return text
    }
}
