import React, { useState, useEffect } from 'react';
import './Management.css';
import adminAPI from '../services/AdminAPI';

const QuestManagement = () => {
  const [quests, setQuests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    fetchQuests();
  }, []);

  const fetchQuests = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const questsData = await adminAPI.getQuests();
      console.log('Quests data from server:', questsData);
      
      if (questsData && Array.isArray(questsData)) {
        setQuests(questsData);
      } else {
        // 서버에서 데이터를 가져올 수 없으면 목업 데이터 사용
        console.warn('서버에서 퀘스트 데이터를 가져올 수 없습니다. 목업 데이터를 사용합니다.');
        setQuests([
          { 
            id: 1, 
            name: '첫 거래 완성하기', 
            type: 'tutorial',
            description: '상인과 첫 거래를 성공적으로 완료하세요',
            status: 'active',
            reward: 500,
            experienceReward: 100,
            difficulty: 'easy',
            completionRate: 85,
            totalCompleted: 1420
          },
          { 
            id: 2, 
            name: '레벨 10 달성', 
            type: 'progression',
            description: '플레이어 레벨을 10까지 올리세요',
            status: 'active',
            reward: 2000,
            experienceReward: 500,
            difficulty: 'normal',
            completionRate: 62,
            totalCompleted: 890
          },
          { 
            id: 3, 
            name: '강남구 정복', 
            type: 'exploration',
            description: '강남구의 모든 상점을 방문하세요',
            status: 'active',
            reward: 5000,
            experienceReward: 1000,
            difficulty: 'hard',
            completionRate: 23,
            totalCompleted: 156
          },
          { 
            id: 4, 
            name: '이벤트: 설날 특별 거래', 
            type: 'event',
            description: '설날 기간 동안 특별 아이템을 거래하세요',
            status: 'inactive',
            reward: 10000,
            experienceReward: 2000,
            difficulty: 'epic',
            completionRate: 8,
            totalCompleted: 45
          },
          { 
            id: 5, 
            name: '백만장자가 되기', 
            type: 'achievement',
            description: '총 자산 100만원을 달성하세요',
            status: 'active',
            reward: 50000,
            experienceReward: 5000,
            difficulty: 'legendary',
            completionRate: 3,
            totalCompleted: 12
          }
        ]);
      }
      
    } catch (error) {
      console.error('퀘스트 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setQuests([
        { 
          id: 1, 
          name: '첫 거래 완성하기', 
          type: 'tutorial',
          description: '상인과 첫 거래를 성공적으로 완료하세요',
          status: 'active',
          reward: 500,
          experienceReward: 100,
          difficulty: 'easy',
          completionRate: 85,
          totalCompleted: 1420
        },
        { 
          id: 2, 
          name: '레벨 10 달성', 
          type: 'progression',
          description: '플레이어 레벨을 10까지 올리세요',
          status: 'active',
          reward: 2000,
          experienceReward: 500,
          difficulty: 'normal',
          completionRate: 62,
          totalCompleted: 890
        },
        { 
          id: 3, 
          name: '강남구 정복', 
          type: 'exploration',
          description: '강남구의 모든 상점을 방문하세요',
          status: 'active',
          reward: 5000,
          experienceReward: 1000,
          difficulty: 'hard',
          completionRate: 23,
          totalCompleted: 156
        },
        { 
          id: 4, 
          name: '이벤트: 설날 특별 거래', 
          type: 'event',
          description: '설날 기간 동안 특별 아이템을 거래하세요',
          status: 'inactive',
          reward: 10000,
          experienceReward: 2000,
          difficulty: 'epic',
          completionRate: 8,
          totalCompleted: 45
        },
        { 
          id: 5, 
          name: '백만장자가 되기', 
          type: 'achievement',
          description: '총 자산 100만원을 달성하세요',
          status: 'active',
          reward: 50000,
          experienceReward: 5000,
          difficulty: 'legendary',
          completionRate: 3,
          totalCompleted: 12
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const filteredQuests = quests.filter(quest => {
    const matchesSearch = quest.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         quest.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || quest.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const sortedQuests = [...filteredQuests].sort((a, b) => {
    switch (sortBy) {
      case 'reward':
        return b.reward - a.reward;
      case 'difficulty':
        const difficultyOrder = { 'easy': 1, 'normal': 2, 'hard': 3, 'epic': 4, 'legendary': 5 };
        return (difficultyOrder[b.difficulty] || 0) - (difficultyOrder[a.difficulty] || 0);
      case 'completion':
        return b.completionRate - a.completionRate;
      case 'type':
        return a.type.localeCompare(b.type);
      default:
        return a.name.localeCompare(b.name);
    }
  });

  const getDifficultyBadgeClass = (difficulty) => {
    switch(difficulty) {
      case 'easy': return 'difficulty-easy';
      case 'normal': return 'difficulty-normal';
      case 'hard': return 'difficulty-hard';
      case 'epic': return 'difficulty-epic';
      case 'legendary': return 'difficulty-legendary';
      default: return 'difficulty-normal';
    }
  };

  const getTypeIcon = (type) => {
    switch(type) {
      case 'tutorial': return '📚';
      case 'progression': return '📈';
      case 'exploration': return '🗺️';
      case 'event': return '🎉';
      case 'achievement': return '🏆';
      default: return '🎯';
    }
  };

  if (loading) {
    return (
      <div className="management-container">
        <div className="loading-spinner">로딩 중...</div>
      </div>
    );
  }

  return (
    <div className="management-container">
      <div className="management-header">
        <h2>🎯 퀘스트 관리</h2>
        <p>플레이어 퀘스트를 생성하고 관리하세요</p>
      </div>

      {error && (
        <div className="error-message" style={{
          background: 'rgba(239, 68, 68, 0.1)',
          border: '1px solid rgba(239, 68, 68, 0.3)',
          color: '#DC2626',
          padding: '1rem',
          borderRadius: '0.5rem',
          marginBottom: '1rem'
        }}>
          ⚠️ {error}
        </div>
      )}

      <div className="management-controls">
        <div className="search-bar">
          <input
            type="text"
            placeholder="퀘스트 이름으로 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="sort-controls">
          <label>상태:</label>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            <option value="all">전체</option>
            <option value="active">활성</option>
            <option value="inactive">비활성</option>
          </select>
        </div>
        <div className="sort-controls">
          <label>정렬:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="name">이름</option>
            <option value="reward">보상</option>
            <option value="difficulty">난이도</option>
            <option value="completion">완료율</option>
            <option value="type">타입</option>
          </select>
        </div>
      </div>

      <div className="data-table">
        <table>
          <thead>
            <tr>
              <th>퀘스트</th>
              <th>타입</th>
              <th>난이도</th>
              <th>보상</th>
              <th>경험치</th>
              <th>완료율</th>
              <th>완료자 수</th>
              <th>상태</th>
              <th>액션</th>
            </tr>
          </thead>
          <tbody>
            {sortedQuests.map(quest => (
              <tr key={quest.id}>
                <td className="player-name">
                  {getTypeIcon(quest.type)} {quest.name}
                  <div className="description-cell">{quest.description}</div>
                </td>
                <td>
                  <span className="category-badge">
                    {quest.type === 'tutorial' ? '튜토리얼' :
                     quest.type === 'progression' ? '진행' :
                     quest.type === 'exploration' ? '탐험' :
                     quest.type === 'event' ? '이벤트' :
                     quest.type === 'achievement' ? '업적' : quest.type}
                  </span>
                </td>
                <td>
                  <span className={`difficulty-badge ${getDifficultyBadgeClass(quest.difficulty)}`}>
                    {quest.difficulty === 'easy' ? '쉬움' :
                     quest.difficulty === 'normal' ? '보통' :
                     quest.difficulty === 'hard' ? '어려움' :
                     quest.difficulty === 'epic' ? '영웅' :
                     quest.difficulty === 'legendary' ? '전설' : quest.difficulty}
                  </span>
                </td>
                <td className="money-cell">
                  {quest.reward.toLocaleString()}골드
                </td>
                <td className="money-cell">
                  {quest.experienceReward.toLocaleString()}EXP
                </td>
                <td>
                  <div className="completion-rate">
                    <div className="completion-bar">
                      <div 
                        className="completion-fill" 
                        style={{width: `${quest.completionRate}%`}}
                      ></div>
                    </div>
                    <span className="completion-text">{quest.completionRate}%</span>
                  </div>
                </td>
                <td>{quest.totalCompleted.toLocaleString()}명</td>
                <td>
                  <span className={`status-badge ${quest.status}`}>
                    {quest.status === 'active' ? '활성' : '비활성'}
                  </span>
                </td>
                <td className="action-cell">
                  <button className="action-btn view">보기</button>
                  <button className="action-btn edit">수정</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="table-footer">
        <span>총 {sortedQuests.length}개의 퀘스트</span>
      </div>
    </div>
  );
};

export default QuestManagement;