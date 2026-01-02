import { create } from 'zustand';
import type { VNNode, StoryChapter } from '../types/story';
import { useQuestStore } from './questStore';

// 태그 제거 정규식
const SPEED_TAG_REGEX = /<\/?[stnfSTNF]>/g;

function cleanText(text: string): string {
    if (!text) return '';
    return text.replace(SPEED_TAG_REGEX, '');
}

interface StoryState {
    // 현재 챕터 데이터
    chapter: StoryChapter | null;

    // 현재 노드
    currentNode: VNNode | null;
    currentNodeIndex: number;

    // 재생 상태
    isPlaying: boolean;
    isTyping: boolean;

    // 타이프라이터 상태
    displayedText: string;
    fullText: string;        // 원본 텍스트 (태그 포함)
    cleanedText: string;     // 정리된 텍스트 (태그 제거)

    // 배경/캐릭터 (이전 값 유지)
    currentBackground: string | null;
    currentCharacterSprite: string | null;

    // 히스토리
    history: string[];

    // 액션
    loadChapter: (chapter: StoryChapter) => void;
    goToNode: (nodeId: string) => void;
    nextNode: () => void;
    previousNode: () => void;
    setTypingComplete: () => void;
    updateDisplayedText: (text: string) => void;
    reset: () => void;
}

export const useStoryStore = create<StoryState>((set, get) => ({
    // 초기 상태
    chapter: null,
    currentNode: null,
    currentNodeIndex: -1,
    isPlaying: false,
    isTyping: false,
    displayedText: '',
    fullText: '',
    cleanedText: '',
    currentBackground: null,
    currentCharacterSprite: null,
    history: [],

    // 챕터 로드
    loadChapter: (chapter) => {
        const startNode = chapter.nodes.find(n => n.node_id === chapter.startNodeId);
        const dialogueText = startNode?.dialogue_text || '';

        set({
            chapter,
            currentNode: startNode || chapter.nodes[0] || null,
            currentNodeIndex: 0,
            isPlaying: true,
            isTyping: true,
            displayedText: '',
            fullText: dialogueText,
            cleanedText: cleanText(dialogueText),
            currentBackground: startNode?.background_image || null,
            currentCharacterSprite: startNode?.character_sprite || null,
            history: startNode ? [startNode.node_id] : [],
        });
    },

    // 특정 노드로 이동
    goToNode: (nodeId) => {
        const { chapter, currentBackground, currentCharacterSprite, history } = get();
        if (!chapter) return;

        const nodeIndex = chapter.nodes.findIndex(n => n.node_id === nodeId);
        const node = chapter.nodes[nodeIndex];

        if (!node) {
            console.warn(`Node not found: ${nodeId}`);
            return;
        }

        const dialogueText = node.dialogue_text || '';

        set({
            currentNode: node,
            currentNodeIndex: nodeIndex,
            isTyping: true,
            displayedText: '',
            fullText: dialogueText,
            cleanedText: cleanText(dialogueText),
            currentBackground: node.background_image || currentBackground,
            currentCharacterSprite: node.character_sprite || currentCharacterSprite,
            history: [...history, nodeId],
        });

        // 퀘스트 스토리 목표 체크
        useQuestStore.getState().checkStoryObjective(nodeId);

        // 퀘스트 해금 트리거 체크
        if (node.unlockQuestIds && node.unlockQuestIds.length > 0) {
            const { unlockQuest, activateQuest } = useQuestStore.getState();
            node.unlockQuestIds.forEach(questId => {
                console.log(`🔓 스토리 노드에서 퀘스트 해금 트리거: ${questId}`);
                unlockQuest(questId);
                activateQuest(questId); // 즉시 활성화 (선택 사항)
            });
        }
    },

    // 다음 노드로 이동
    nextNode: () => {
        const { currentNode, isTyping, cleanedText } = get();

        // 타이핑 중이면 완료 처리 (정리된 텍스트 사용)
        if (isTyping) {
            set({ isTyping: false, displayedText: cleanedText });
            return;
        }

        // 다음 노드로 이동
        if (currentNode?.next_node_id) {
            get().goToNode(currentNode.next_node_id);
        } else {
            // 스토리 끝
            set({ isPlaying: false });
        }
    },

    // 이전 노드로 이동
    previousNode: () => {
        const { history, chapter } = get();

        if (history.length <= 1 || !chapter) return;

        const newHistory = history.slice(0, -1);
        const prevNodeId = newHistory[newHistory.length - 1];
        const prevNode = chapter.nodes.find(n => n.node_id === prevNodeId);

        if (prevNode) {
            const dialogueText = prevNode.dialogue_text || '';
            const cleaned = cleanText(dialogueText);

            set({
                currentNode: prevNode,
                currentNodeIndex: chapter.nodes.findIndex(n => n.node_id === prevNodeId),
                isTyping: false,
                displayedText: cleaned,
                fullText: dialogueText,
                cleanedText: cleaned,
                history: newHistory,
            });
        }
    },

    // 타이핑 완료 (정리된 텍스트 사용)
    setTypingComplete: () => {
        set({ isTyping: false, displayedText: get().cleanedText });
    },

    // 표시할 텍스트 업데이트 (타이프라이터용)
    updateDisplayedText: (text) => {
        set({ displayedText: text });
    },

    // 리셋
    reset: () => {
        set({
            chapter: null,
            currentNode: null,
            currentNodeIndex: -1,
            isPlaying: false,
            isTyping: false,
            displayedText: '',
            fullText: '',
            cleanedText: '',
            currentBackground: null,
            currentCharacterSprite: null,
            history: [],
        });
    },
}));
