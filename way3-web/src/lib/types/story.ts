/**
 * WAY3 Story Types
 * Visual Novel 노드 및 챕터 타입 정의
 */

// VN 노드 타입
export type VNNodeType = 'dialogue' | 'decision' | 'conditional' | 'questGate';

// 기본 VN 노드 (대화)
export interface VNNode {
    node_id: string;
    background_image: string | null;
    character_id: string;
    character_sprite: string | null;
    dialogue_text: string;
    dialogue_sound_id: string | null;
    sound_effect: string | null;
    next_node_id: string | null;

    // 퀘스트 해금 트리거
    unlockQuestIds?: string[];
}

// 선택지
export interface VNChoice {
    id: string;
    text: string;
    next_node_id: string;
}

// 선택지 노드
export interface VNDecisionNode extends VNNode {
    type: 'decision';
    prompt?: string;
    choices: VNChoice[];
}

// 조건 분기 노드
export interface VNConditionalNode extends VNNode {
    type: 'conditional';
    condition: {
        type: string;
        value: string | number | boolean;
    };
    on_success: string;
    on_failure: string;
}

// 챕터 데이터
export interface StoryChapter {
    id: string;
    title: string;
    nodeCount: number;
    startNodeId: string | null;
    nodes: VNNode[];
}

// 챕터 인덱스
export interface StoryIndex {
    version: string;
    buildTime: string;
    chapters: {
        id: string;
        title: string;
        nodeCount: number;
        startNodeId: string;
    }[];
}

// 스토리 상태
export interface StoryState {
    currentChapterId: string | null;
    currentNodeId: string | null;
    isPlaying: boolean;
    isTyping: boolean;
    displayedText: string;
    history: string[]; // 방문한 노드 ID 목록
}

// 캐릭터 정보
export interface Character {
    id: string;
    name: string;
    gender: 'male' | 'female' | 'neutral' | 'typer';
    blip?: string; // 대화 효과음
}

// 캐릭터 맵
export interface CharacterMap {
    [key: string]: Character;
}
