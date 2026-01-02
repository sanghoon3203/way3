'use client';
import dynamic from 'next/dynamic';
import { useGPSStore } from '@/lib/store/gpsStore';
import { useUser } from '@/lib/hooks/useUser';
import styles from './GPSSimulator.module.css';
import { useEffect } from 'react';

// Mapbox는 클라이언트 전용이므로 dynamic import
const MapboxMap = dynamic(() => import('@/components/map/MapboxMap'), {
    ssr: false,
    loading: () => (
        <div className={styles.mapLoading}>
            <span>🗺️</span>
            <span>지도 로딩 중...</span>
        </div>
    ),
});

export default function GPSSimulator() {
    const {
        currentLat,
        currentLng,
        nearbyMerchants,
        selectedMerchant,
        zoomIn,
        zoomOut,
        setPosition,
        selectMerchant,
        updateNearbyMerchants,
    } = useGPSStore();

    const { user, fetchUser } = useUser();

    // 초기 로드 시 유저 데이터 갱신
    useEffect(() => {
        fetchUser();
    }, []);

    // 컴포넌트 마운트 시 근처 상인 업데이트
    if (nearbyMerchants.length === 0) {
        updateNearbyMerchants();
    }

    const handleMapClick = (lat: number, lng: number) => {
        setPosition(lat, lng);
        selectMerchant(null);
    };

    const handleResetPosition = () => {
        // 강남역 근처로 리셋
        setPosition(37.4979, 127.0276);
    };

    return (
        <div className={`${styles.container} panel`}>
            {/* Header */}
            <div className={styles.header}>
                <div className={styles.headerLeft}>
                    <span className={styles.icon}>🗺️</span>
                    <h3 className={styles.title}>GPS 시뮬레이터</h3>
                </div>
                <div className={styles.coordinates}>
                    <span className={styles.coordLabel}>현재 위치</span>
                    <span className={styles.coordValue}>
                        {currentLat.toFixed(4)}, {currentLng.toFixed(4)}
                    </span>
                </div>
            </div>

            {/* Map Area */}
            <div className={styles.mapArea}>
                <MapboxMap onMapClick={handleMapClick} />

                {/* 플레이어 크레딧 표시 (Mapbox 로고 위에 오버레이) */}
                <div className={styles.creditsOverlay}>
                    <span className={styles.creditsIcon}>💰</span>
                    <span className={styles.creditsValue}>
                        {user ? user.credits.toLocaleString() : '...'}
                    </span>
                    <span className={styles.creditsLabel}>크레딧</span>
                </div>

                {/* Map Controls */}
                <div className={styles.mapControls}>
                    <button className={styles.controlBtn} onClick={zoomIn} title="확대">
                        <span>+</span>
                    </button>
                    <button className={styles.controlBtn} onClick={zoomOut} title="축소">
                        <span>−</span>
                    </button>
                    <button className={styles.controlBtn} onClick={handleResetPosition} title="위치 초기화">
                        <span>📍</span>
                    </button>
                </div>
            </div>

            {/* Status Bar */}
            <div className={styles.statusBar}>
                <div className={styles.statusItem}>
                    <span className={styles.statusDot} />
                    <span>반경 3km 내 상인: {nearbyMerchants.length}명</span>
                </div>

                {selectedMerchant ? (
                    <div className={styles.selectedMerchant}>
                        <span className={styles.merchantName}>{selectedMerchant.name}</span>
                        <span className={styles.merchantDistrict}>{selectedMerchant.district}</span>
                    </div>
                ) : (
                    <div className={styles.statusItem}>
                        <span className={styles.statusHint}>지도를 클릭하여 위치 이동</span>
                    </div>
                )}
            </div>
        </div>
    );
}

