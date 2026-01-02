import { create } from 'zustand';
import { useQuestStore } from './questStore';

// 상인 데이터 타입
export interface Merchant {
    id: string;
    name: string;
    lat: number;
    lng: number;
    faceshot?: string;
    district?: string;
    isNearby?: boolean;
}

// GPS 상태 타입
interface GPSState {
    // 현재 위치
    currentLat: number;
    currentLng: number;

    // 줌 레벨
    zoom: number;

    // 상인 목록
    merchants: Merchant[];
    nearbyMerchants: Merchant[];

    // 선택된 상인
    selectedMerchant: Merchant | null;

    // 반경 (미터)
    radius: number;

    // 액션
    setPosition: (lat: number, lng: number) => void;
    setZoom: (zoom: number) => void;
    zoomIn: () => void;
    zoomOut: () => void;
    setMerchants: (merchants: Merchant[]) => void;
    selectMerchant: (merchant: Merchant | null) => void;
    setRadius: (radius: number) => void;
    updateNearbyMerchants: () => void;
}

// 두 좌표 사이의 거리 계산 (미터)
function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371000; // 지구 반경 (미터)
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lng2 - lng1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) *
        Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
}

// 초기 상인 데이터 (강남권)
const initialMerchants: Merchant[] = [
    { id: 'seoyena', name: '서예나', lat: 37.5172, lng: 127.0473, district: '강남구', faceshot: '/merchants/Seoyena/Merchant_seoyena_face.png' },
    { id: 'jubulsu', name: '주불수', lat: 37.5013, lng: 127.0396, district: '서초구', faceshot: '/merchants/Jubulsu/Merchant_jubulsu_face.png' },
    { id: 'anipark', name: '애니', lat: 37.5087, lng: 127.1002, district: '송파구', faceshot: '/merchants/AniPark/Merchant_anipark_face.png' },
    { id: 'kijuri', name: '기주리', lat: 37.4979, lng: 127.0276, district: '종로구', faceshot: '/merchants/Kijuri/Merchant_kijuri_face.png' },
    { id: 'alicegang', name: '앨리스', lat: 37.5079, lng: 127.0276, district: '서초구', faceshot: '/merchants/AliceGang/Merchant_alicegang_face.png' },
    { id: 'mari', name: '마리', lat: 37.5523, lng: 126.9217, district: '마포구', faceshot: '/merchants/Mari/Merchant_mari_face.png' },
    { id: 'catarinachoi', name: '카티리나 최', lat: 37.5279, lng: 126.9276, district: '남구', faceshot: '/merchants/CatarinaChoi/Merchant_catarinachoi_face.png' },
    { id: 'jinbaekho', name: '진백호', lat: 37.5260, lng: 127.1243, district: '강동구', faceshot: '/merchants/Jinbaekho/Merchant_jinbaekho_face.png' },
    { id: 'kimsehwui', name: '김세휘', lat: 37.5279, lng: 126.9276, district: '관악구', faceshot: '/merchants/Kimsehwui/Merchant_kimsehwui_face.png' },
];

// 초기 위치: 강남역 근처
const INITIAL_LAT = 37.4979;
const INITIAL_LNG = 127.0276;

export const useGPSStore = create<GPSState>((set, get) => ({
    // 초기 상태
    currentLat: INITIAL_LAT,
    currentLng: INITIAL_LNG,
    zoom: 13,
    merchants: initialMerchants,
    nearbyMerchants: [],
    selectedMerchant: null,
    radius: 3000, // 3km 기본 반경

    // 위치 설정
    setPosition: (lat, lng) => {
        set({ currentLat: lat, currentLng: lng });
        get().updateNearbyMerchants();

        // 퀘스트 GPS 목표 체크
        useQuestStore.getState().checkGPSObjective(lat, lng);
    },

    // 줌 설정
    setZoom: (zoom) => set({ zoom: Math.max(10, Math.min(18, zoom)) }),

    zoomIn: () => set((state) => ({ zoom: Math.min(18, state.zoom + 1) })),

    zoomOut: () => set((state) => ({ zoom: Math.max(10, state.zoom - 1) })),

    // 상인 목록 설정
    setMerchants: (merchants) => {
        set({ merchants });
        get().updateNearbyMerchants();
    },

    // 상인 선택
    selectMerchant: (merchant) => set({ selectedMerchant: merchant }),

    // 반경 설정
    setRadius: (radius) => {
        set({ radius });
        get().updateNearbyMerchants();
    },

    // 근처 상인 업데이트
    updateNearbyMerchants: () => {
        const { currentLat, currentLng, merchants, radius } = get();

        const nearby = merchants.map(merchant => {
            const distance = calculateDistance(currentLat, currentLng, merchant.lat, merchant.lng);
            return {
                ...merchant,
                isNearby: distance <= radius,
            };
        }).filter(m => m.isNearby);

        set({ nearbyMerchants: nearby });
    },
}));
