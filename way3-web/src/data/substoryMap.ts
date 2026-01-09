// Merchant ID와 서브스토리 파일 매핑
export const substoryMap: Record<string, string> = {
    'seoyena': 'seoyena.json',
    'alicegang': 'alicegang.json',
    'anipark': 'anipark.json',
    'jinbaekho': 'jinbaekho.json',
    'jubulsu': 'jubulsu.json',
};

// 서브스토리가 있는지 확인
export function hasSubstory(merchantId: string): boolean {
    return merchantId in substoryMap;
}

// 서브스토리 파일명 가져오기
export function getSubstoryFile(merchantId: string): string | null {
    return substoryMap[merchantId] || null;
}
