//
//  BackgroundVideoLayer.swift
//  way3 - Way Trading Game
//
//  공통 배경 비디오 레이어 컴포넌트
//  모든 Auth 화면에서 재사용 가능
//

import SwiftUI
import AVKit

// MARK: - 기본 BackgroundVideoLayer
struct BackgroundVideoLayer: View {
    let videoName: String
    let videoExtension: String
    let directory: String?

    @State private var player: AVPlayer?

    // 기본 생성자 (기존 호환성 유지)
    init(videoName: String = "bgmv1", videoExtension: String = "mp4", directory: String? = "Bgmv") {
        self.videoName = videoName
        self.videoExtension = videoExtension
        self.directory = directory
    }

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Fallback 그라데이션 배경
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.05, blue: 0.2),
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            setupVideo()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupVideo() {
        let videoPath: String?

        if let directory = directory {
            videoPath = Bundle.main.path(forResource: videoName, ofType: videoExtension, inDirectory: directory)
        } else {
            videoPath = Bundle.main.path(forResource: videoName, ofType: videoExtension)
        }

        guard let path = videoPath else {
            print("⚠️ 배경 영상을 찾을 수 없습니다: \(directory ?? "")/\(videoName).\(videoExtension)")
            return
        }

        let videoURL = URL(fileURLWithPath: path)
        player = AVPlayer(url: videoURL)
        player?.isMuted = true

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player?.play()
    }
}

// MARK: - StartView용 고급 BackgroundVideoLayer
struct StartViewBackgroundLayer: View {
    @State private var player: AVPlayer?
    @State private var currentBackgroundImage: String = ""
    @State private var showVideo = true
    @State private var selectedVideoName = ""

    private let videoOptions = ["bgmv1", "bgmv2"]

    var body: some View {
        ZStack {
            if showVideo {
                // 비디오 재생
                if let player = player {
                    VideoPlayer(player: player)
                        .disabled(true)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    // Fallback 그라데이션
                    FallbackGradient()
                }
            } else {
                // 비디오 종료 후 이미지 표시
                if !currentBackgroundImage.isEmpty {
                    Image(currentBackgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .transition(.opacity)
                } else {
                    FallbackGradient()
                }
            }
        }
        .onAppear {
            setupRandomVideo()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupRandomVideo() {
        // 랜덤으로 비디오 선택
        selectedVideoName = videoOptions.randomElement() ?? "bgmv1"

        // 선택된 비디오에 따라 배경 이미지 설정
        currentBackgroundImage = selectedVideoName == "bgmv1" ? "bg1" : "bg2"

        guard let videoPath = Bundle.main.path(forResource: selectedVideoName, ofType: "mp4", inDirectory: "Bgmv") else {
            print("⚠️ 배경 영상을 찾을 수 없습니다: Bgmv/\(selectedVideoName).mp4")
            // 비디오가 없으면 바로 이미지로 전환
            showVideo = false
            return
        }

        let videoURL = URL(fileURLWithPath: videoPath)
        player = AVPlayer(url: videoURL)
        player?.isMuted = true

        // 비디오 종료 시 이미지로 전환
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                showVideo = false
            }
        }

        player?.play()
        print("🎥 랜덤 선택된 비디오: \(selectedVideoName) → 이후 배경: \(currentBackgroundImage)")
    }

    private func FallbackGradient() -> some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}