//
//  LoginView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  Pokemon GO 스타일 로그인 화면
//

import SwiftUI

struct LoginView: View {
    @Binding var showLoginView: Bool
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var playerName = ""
    @State private var isRegistering = false
    @State private var showPassword = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 그라데이션 (Pokemon GO 스타일)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.8),
                        Color(.systemIndigo).opacity(0.9),
                        Color(.systemPurple).opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 움직이는 파티클 효과
                ParticleEffectView()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 80)
                        
                        // 로고 및 타이틀
                        VStack(spacing: 20) {
                            // Way3 로고
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 10)
                                
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                    .shadow(radius: 10)
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showLoginView)
                            
                            VStack(spacing: 8) {
                                Text("Way3")
                                    .font(.custom("ChosunCentennial", size: 36))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                
                                Text("위치기반 무역 게임")
                                    .font(.custom("ChosunCentennial", size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(radius: 3)
                            }
                        }
                        
                        // 로그인/회원가입 폼
                        VStack(spacing: 25) {
                            // 탭 선택
                            HStack {
                                ForEach([false, true], id: \.self) { isRegister in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            isRegistering = isRegister
                                        }
                                    }) {
                                        VStack(spacing: 5) {
                                            Text(isRegister ? "회원가입" : "로그인")
                                                .font(.custom("ChosunCentennial", size: 18))
                                                .foregroundColor(isRegistering == isRegister ? .white : .white.opacity(0.6))
                                            
                                            Rectangle()
                                                .frame(height: 2)
                                                .foregroundColor(isRegistering == isRegister ? .white : .clear)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 입력 필드들
                            VStack(spacing: 20) {
                                // 이메일
                                CustomTextField(
                                    text: $email,
                                    placeholder: "이메일",
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                                
                                // 비밀번호
                                CustomSecureField(
                                    text: $password,
                                    placeholder: "비밀번호",
                                    showPassword: $showPassword
                                )
                                
                                // 회원가입시 플레이어 이름
                                if isRegistering {
                                    CustomTextField(
                                        text: $playerName,
                                        placeholder: "플레이어 이름",
                                        icon: "person.fill",
                                        keyboardType: .default
                                    )
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 에러 메시지
                            if !authManager.errorMessage.isEmpty {
                                Text(authManager.errorMessage)
                                    .font(.custom("ChosunCentennial", size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // 로그인/회원가입 버튼
                            Button(action: {
                                Task {
                                    if isRegistering {
                                        await authManager.register(email: email, password: password, playerName: playerName)
                                    } else {
                                        await authManager.login(email: email, password: password)
                                    }
                                    
                                    if authManager.isAuthenticated {
                                        showLoginView = false
                                    }
                                }
                            }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isRegistering ? "person.badge.plus" : "arrow.right.circle.fill")
                                            .font(.title2)
                                    }
                                    
                                    Text(isRegistering ? "계정 만들기" : "게임 시작")
                                        .font(.custom("ChosunCentennial", size: 18))
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 27.5)
                                        .fill(isFormValid ? Color.orange : Color.gray)
                                        .shadow(radius: 10)
                                )
                            }
                            .disabled(!isFormValid || authManager.isLoading)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.15))
                                .blur(radius: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth {
                showLoginView = false
            }
        }
    }
    
    // 폼 유효성 검사
    private var isFormValid: Bool {
        if isRegistering {
            return !email.isEmpty && !password.isEmpty && !playerName.isEmpty && 
                   email.contains("@") && password.count >= 6 && playerName.count >= 2
        } else {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        }
    }
}

// MARK: - 커스텀 텍스트 필드
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 25)
            
            TextField(placeholder, text: $text)
                .font(.custom("ChosunCentennial", size: 16))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
        )
    }
}

// MARK: - 커스텀 보안 텍스트 필드
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 25)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
        )
    }
}

// MARK: - 파티클 효과
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 2)
                }
            }
        }
        .onAppear {
            createParticles()
            startParticleAnimation()
        }
    }
    
    private func createParticles() {
        particles = (0..<20).map { _ in
            Particle(
                id: UUID(),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...8)
            )
        }
    }
    
    private func startParticleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                for i in particles.indices {
                    particles[i].y -= CGFloat.random(in: 0.5...2)
                    particles[i].x += CGFloat.random(in: -1...1)
                    
                    if particles[i].y < -10 {
                        particles[i].y = UIScreen.main.bounds.height + 10
                        particles[i].x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                    }
                }
            }
        }
    }
}

struct Particle {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
}