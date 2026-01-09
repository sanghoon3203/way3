import { create } from 'zustand';
import type { Merchant } from './gpsStore';
import type { StoryChapter } from '@/lib/types/story';

// 채팅 메시지 타입
export interface ChatMessage {
    id: string;
    characterId: string | null;
    characterName: string;
    text: string;
    isPlayer: boolean;
    timestamp: Date;
    avatar?: string;
}

// 채팅 상태 타입
interface ChatState {
    // 현재 선택된 캐릭터
    activeMerchant: Merchant | null;

    // 표시된 메시지 목록
    messages: ChatMessage[];

    // 현재 진행 위치 (노드 인덱스)
    currentNodeIndex: number;

    // 로드된 서브스토리 데이터
    substoryData: StoryChapter | null;

    // 채팅이 완료되었는지
    isComplete: boolean;

    // 액션
    openChat: (merchant: Merchant, substoryData: StoryChapter) => void;
    closeChat: () => void;
    sendMessage: () => void; // 다음 대사로 진행
    reset: () => void;
}

// 캐릭터 ID를 한글 이름으로 변환
function getCharacterName(characterId: string | null, merchantName: string): string {
    if (!characterId) return '나레이션';
    if (characterId === 'player') return '나';
    if (characterId === 'System') return '시스템';
    // 기본적으로 merchant 이름 반환
    return merchantName;
}

export const useChatStore = create<ChatState>((set, get) => ({
    // 초기 상태
    activeMerchant: null,
    messages: [],
    currentNodeIndex: 0,
    substoryData: null,
    isComplete: false,

    // 채팅 열기
    openChat: (merchant, substoryData) => {
        const firstNode = substoryData.nodes[0];
        const initialMessage: ChatMessage = {
            id: `msg-0`,
            characterId: firstNode.character_id,
            characterName: getCharacterName(firstNode.character_id, merchant.name),
            text: firstNode.dialogue_text,
            isPlayer: firstNode.character_id === 'player',
            timestamp: new Date(),
            avatar: merchant.faceshot,
        };

        set({
            activeMerchant: merchant,
            substoryData,
            messages: [initialMessage],
            currentNodeIndex: 0,
            isComplete: false,
        });
    },

    // 채팅 닫기
    closeChat: () => {
        set({
            activeMerchant: null,
            messages: [],
            currentNodeIndex: 0,
            substoryData: null,
            isComplete: false,
        });
    },

    // 다음 메시지로 진행
    sendMessage: () => {
        const { substoryData, currentNodeIndex, messages, activeMerchant, isComplete } = get();

        if (!substoryData || !activeMerchant || isComplete) return;

        const nextIndex = currentNodeIndex + 1;

        if (nextIndex >= substoryData.nodes.length) {
            set({ isComplete: true });
            return;
        }

        const nextNode = substoryData.nodes[nextIndex];
        const newMessage: ChatMessage = {
            id: `msg-${nextIndex}`,
            characterId: nextNode.character_id,
            characterName: getCharacterName(nextNode.character_id, activeMerchant.name),
            text: nextNode.dialogue_text,
            isPlayer: nextNode.character_id === 'player',
            timestamp: new Date(),
            avatar: activeMerchant.faceshot,
        };

        set({
            messages: [...messages, newMessage],
            currentNodeIndex: nextIndex,
        });
    },

    // 리셋
    reset: () => {
        set({
            activeMerchant: null,
            messages: [],
            currentNodeIndex: 0,
            substoryData: null,
            isComplete: false,
        });
    },
}));
