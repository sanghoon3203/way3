'use client';
import { useEffect, useRef } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { useGPSStore, type Merchant } from '@/lib/store/gpsStore';
import styles from '@/components/layout/GPSSimulator.module.css';
import { useUser } from '@/lib/hooks/useUser';
import { districtBoundaries } from '@/data/map/seoul-districts';

// 상인 ID -> 구역 매핑
const getMerchantDistrict = (merchantId: string): string => {
    const mapping: Record<string, string> = {
        'seoyena': 'gangnam',
        'mari': 'outside',
        'catarinachoi': 'outside',
        'alicegang': 'seocho',
        'jubulsu': 'seocho',
        'anipark': 'songpa',
        'jinbaekho': 'gangdong',
        'kimsehwui': 'outside' // 잠김 처리
    };
    return mapping[merchantId] || 'gangnam';
};

// Mapbox 토큰 설정
const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '';

// ... (중간 코드 유지) ...



interface MapboxMapProps {
    onMapClick?: (lat: number, lng: number) => void;
    variant?: 'desktop' | 'mobile';
}

export default function MapboxMap({ onMapClick, variant = 'desktop' }: MapboxMapProps) {
    const mapContainer = useRef<HTMLDivElement>(null);
    const map = useRef<mapboxgl.Map | null>(null);
    const markersRef = useRef<mapboxgl.Marker[]>([]);
    const positionMarkerRef = useRef<mapboxgl.Marker | null>(null);

    const {
        currentLat,
        currentLng,
        zoom,
        merchants,
        selectedMerchant,
        setPosition,
        setZoom,
        selectMerchant,
    } = useGPSStore();

    const { user } = useUser();

    // 해금된 구역 목록 (기본값: 강남)
    const unlockedDistricts = user?.unlockedDistricts
        ? JSON.parse(user.unlockedDistricts) as string[]
        : ['gangnam'];

    // 3D 빌딩 레이어 추가 함수
    const add3DBuildings = (mapInstance: mapboxgl.Map) => {
        const layers = mapInstance.getStyle().layers;
        if (!layers) return;

        const labelLayerId = layers.find(
            (layer) => layer.type === 'symbol' && layer.layout && 'text-field' in layer.layout
        )?.id;

        mapInstance.addLayer(
            {
                'id': 'add-3d-buildings',
                'source': 'composite',
                'source-layer': 'building',
                'filter': ['==', 'extrude', 'true'],
                'type': 'fill-extrusion',
                'minzoom': 15,
                'paint': {
                    'fill-extrusion-color': '#aaa',
                    'fill-extrusion-height': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        15,
                        0,
                        15.05,
                        ['get', 'height']
                    ],
                    'fill-extrusion-base': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        15,
                        0,
                        15.05,
                        ['get', 'min_height']
                    ],
                    'fill-extrusion-opacity': 0.6
                }
            },
            labelLayerId
        );
    };

    // 안개 레이어 추가 함수 (사용자 요청으로 제거됨)
    const addFogLayers = (mapInstance: mapboxgl.Map) => {
        // 안개 효과 제거됨.
        // 김세휘 등 locked 상인 처리는 getMerchantDistrict에서 처리됨.
    };

    // 지도 초기화
    useEffect(() => {
        if (!mapContainer.current || map.current) return;

        if (!MAPBOX_TOKEN) {
            console.warn('Mapbox token not set. Add NEXT_PUBLIC_MAPBOX_TOKEN to .env.local');
            return;
        }

        mapboxgl.accessToken = MAPBOX_TOKEN;

        const isMobile = variant === 'mobile';

        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/dark-v11',
            center: [currentLng, currentLat],
            zoom: isMobile ? 16 : zoom,
            pitch: 45,
            bearing: -17.6,
            antialias: true,
        });

        map.current.on('style.load', () => {
            if (map.current) {
                add3DBuildings(map.current);
                addFogLayers(map.current);
            }
        });

        map.current.on('click', (e) => {
            const { lat, lng } = e.lngLat;
            setPosition(lat, lng);
            onMapClick?.(lat, lng);
        });

        map.current.on('zoomend', () => {
            if (map.current) {
                setZoom(map.current.getZoom());
            }
        });

        if (!isMobile) {
            map.current.addControl(new mapboxgl.NavigationControl(), 'top-right');
        }

        return () => {
            map.current?.remove();
            map.current = null;
        };
    }, [variant]);

    // 현재 위치 마커 업데이트
    useEffect(() => {
        if (!map.current) return;

        if (positionMarkerRef.current) {
            positionMarkerRef.current.remove();
        }

        const el = document.createElement('div');
        el.className = styles.currentPositionMarker;
        el.innerHTML = `
      <div class="${styles.positionRing}"></div>
      <div class="${styles.positionDot}"></div>
    `;

        positionMarkerRef.current = new mapboxgl.Marker(el)
            .setLngLat([currentLng, currentLat])
            .addTo(map.current);

        // 현재 지도 중심과 새 위치 사이 거리 계산
        const currentCenter = map.current.getCenter();
        const distance = Math.sqrt(
            Math.pow(currentCenter.lat - currentLat, 2) +
            Math.pow(currentCenter.lng - currentLng, 2)
        );

        // 거리에 따라 이동 방식 변경 (0.01 ≈ 약 1km)
        if (distance > 0.05) {
            // 먼 거리: 즉시 이동 (freezing 방지)
            map.current.jumpTo({
                center: [currentLng, currentLat],
            });
        } else {
            // 가까운 거리: 부드럽게 이동
            map.current.easeTo({
                center: [currentLng, currentLat],
                duration: 300,
            });
        }
    }, [currentLat, currentLng]);

    // 상인 마커 업데이트
    useEffect(() => {
        if (!map.current) return;

        markersRef.current.forEach(marker => marker.remove());
        markersRef.current = [];

        merchants.forEach((merchant) => {
            const district = getMerchantDistrict(merchant.id);
            const isLocked = !unlockedDistricts.includes(district);

            const el = document.createElement('div');
            // 잠긴 상태 스타일에 따라 클래스 변경
            el.className = isLocked ? styles.merchantMarkerLocked : styles.merchantMarkerMapbox;

            // 잠긴 상인은 ??? 및 물음표 아이콘
            const displayName = isLocked ? '???' : merchant.name;
            const imageHtml = isLocked
                ? `<span class="${styles.markerEmoji}">❓</span>`
                : merchant.faceshot
                    ? `<img src="${merchant.faceshot}" alt="${merchant.name}" class="${styles.markerImage}" />`
                    : `<span class="${styles.markerEmoji}">👤</span>`;

            el.innerHTML = `
        <div class="${styles.markerCircle} ${isLocked ? styles.locked : ''}">
          ${imageHtml}
        </div>
        <div class="${styles.markerLabel}">${displayName}</div>
      `;

            // 잠기지 않은 경우에만 클릭 이벤트
            if (!isLocked) {
                el.addEventListener('click', (e) => {
                    e.stopPropagation();
                    selectMerchant(merchant);
                });
            }

            const marker = new mapboxgl.Marker(el)
                .setLngLat([merchant.lng, merchant.lat])
                .addTo(map.current!);

            markersRef.current.push(marker);
        });
    }, [merchants, selectMerchant, unlockedDistricts]);

    // 줌 레벨 동기화
    useEffect(() => {
        if (map.current && map.current.getZoom() !== zoom) {
            map.current.setZoom(zoom);
        }
    }, [zoom]);

    if (!MAPBOX_TOKEN) {
        return (
            <div className={styles.mapPlaceholder}>
                <div className={styles.placeholderContent}>
                    <span className={styles.placeholderIcon}>🗺️</span>
                    <p className={styles.placeholderText}>Mapbox 토큰 필요</p>
                    <p className={styles.placeholderHint}>
                        .env.local에 NEXT_PUBLIC_MAPBOX_TOKEN 설정
                    </p>
                </div>
            </div>
        );
    }

    return <div ref={mapContainer} className={styles.mapContainer} />;
}
