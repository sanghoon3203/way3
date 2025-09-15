//
//  LocationTrackingButton.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Map/Components/LocationTrackingButton.swift
import SwiftUI
import MapboxMaps

struct LocationTrackingButton: View {
    @Binding var isTracking: Bool
    @Binding var viewport: Viewport
    
    var body: some View {
        Button(action: toggleTracking) {
            Image(systemName: isTracking ? "location.fill" : "location")
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
    
    private func toggleTracking() {
        isTracking.toggle()
        
        if isTracking {
            // 위치 추적 시작
            withViewportAnimation(.default(maxDuration: 1.3)) {
                viewport = .followPuck(zoom: 15)
            }
        } else {
            // 위치 추적 중단
            viewport = .idle
        }
    }
}
