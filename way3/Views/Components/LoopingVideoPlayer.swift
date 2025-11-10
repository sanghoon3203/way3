//
//  LoopingVideoPlayer.swift
//  way3
//
//  MOV 비디오 무한 루프 재생 컴포넌트
//  투명 배경(alpha channel) 지원
//

import SwiftUI
import AVFoundation
import AVKit

/// MOV 파일을 무한 루프로 재생하는 비디오 플레이어
struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(videoName: videoName)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playerView = uiView as? LoopingPlayerUIView else { return }
        playerView.updateVideo(videoName: videoName)
    }
}

// MARK: - LoopingPlayerUIView
class LoopingPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var currentVideoName: String?

    init(videoName: String) {
        super.init(frame: .zero)
        self.currentVideoName = videoName
        setupPlayer(videoName: videoName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateVideo(videoName: String) {
        // 같은 비디오면 아무것도 안 함
        guard videoName != currentVideoName else { return }

        currentVideoName = videoName

        // 기존 플레이어 정리
        playerLooper = nil
        player?.pause()
        playerLayer?.removeFromSuperlayer()

        // 새 비디오로 재설정
        setupPlayer(videoName: videoName)
    }

    private func setupPlayer(videoName: String) {
        // 비디오 파일 찾기 (대소문자 모두 시도)
        var videoURL = Bundle.main.url(forResource: videoName, withExtension: "mov")
        if videoURL == nil {
            videoURL = Bundle.main.url(forResource: videoName, withExtension: "MOV")
        }

        guard let videoURL = videoURL else {
            print("⚠️ MOV 파일을 찾을 수 없음: \(videoName).mov/.MOV")
            return
        }

        // AVPlayerItem 생성
        let playerItem = AVPlayerItem(url: videoURL)

        // AVQueuePlayer 생성 (루프용)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.player = queuePlayer

        // 무한 루프 설정
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        // AVPlayerLayer 생성
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.videoGravity = .resizeAspect  // 비율 유지
        playerLayer.frame = self.bounds

        // 투명 배경 지원
        playerLayer.backgroundColor = UIColor.clear.cgColor
        self.backgroundColor = .clear

        self.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer

        // 재생 시작
        queuePlayer.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    deinit {
        player?.pause()
        playerLooper = nil
    }
}

// MARK: - Preview
#Preview {
    LoopingVideoPlayer(videoName: "merchant_seoyena_talking")
        .frame(width: 224, height: 400)
        .background(Color.gray.opacity(0.3))
}
