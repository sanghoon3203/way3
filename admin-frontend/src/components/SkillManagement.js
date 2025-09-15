import React, { useState, useEffect } from 'react';
import './Management.css';
import adminAPI from '../services/AdminAPI';

const SkillManagement = () => {
  const [skills, setSkills] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [categoryFilter, setCategoryFilter] = useState('all');

  useEffect(() => {
    fetchSkills();
  }, []);

  const fetchSkills = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const skillsData = await adminAPI.getSkills();
      console.log('Skills data from server:', skillsData);
      
      if (skillsData && Array.isArray(skillsData)) {
        setSkills(skillsData);
      } else {
        // 서버에서 데이터를 가져올 수 없으면 목업 데이터 사용
        console.warn('서버에서 스킬 데이터를 가져올 수 없습니다. 목업 데이터를 사용합니다.');
        setSkills([
          { 
            id: 1, 
            name: '거래 달인', 
            category: 'trading',
            description: '거래 성공률과 수익을 증가시킵니다',
            maxLevel: 10,
            currentLevel: 5,
            effect: '거래 성공률 +50%, 수익 +25%',
            cost: 1000,
            unlockLevel: 5,
            prerequisite: null,
            learnedBy: 1250
          },
          { 
            id: 2, 
            name: '운송 마스터', 
            category: 'transportation',
            description: '이동 속도와 운반 용량을 증가시킵니다',
            maxLevel: 8,
            currentLevel: 3,
            effect: '이동속도 +30%, 운반용량 +40%',
            cost: 800,
            unlockLevel: 3,
            prerequisite: null,
            learnedBy: 890
          },
          { 
            id: 3, 
            name: '협상 전문가', 
            category: 'social',
            description: '상인과의 협상에서 유리한 조건을 얻습니다',
            maxLevel: 5,
            currentLevel: 2,
            effect: '가격 할인 +20%, 특별 거래 확률 +15%',
            cost: 1500,
            unlockLevel: 8,
            prerequisite: '거래 달인',
            learnedBy: 456
          },
          { 
            id: 4, 
            name: '시장 분석가', 
            category: 'analysis',
            description: '시장 동향을 파악하고 최적의 거래 타이밍을 찾습니다',
            maxLevel: 7,
            currentLevel: 4,
            effect: '시장 정보 정확도 +60%, 가격 예측 +40%',
            cost: 2000,
            unlockLevel: 12,
            prerequisite: '협상 전문가',
            learnedBy: 234
          },
          { 
            id: 5, 
            name: '리스크 매니저', 
            category: 'management',
            description: '거래 위험을 최소화하고 손실을 방지합니다',
            maxLevel: 6,
            currentLevel: 1,
            effect: '손실 방지 +25%, 보험료 할인 +30%',
            cost: 2500,
            unlockLevel: 15,
            prerequisite: '시장 분석가',
            learnedBy: 89
          }
        ]);
      }
      
    } catch (error) {
      console.error('스킬 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setSkills([
        { 
          id: 1, 
          name: '거래 달인', 
          category: 'trading',
          description: '거래 성공률과 수익을 증가시킵니다',
          maxLevel: 10,
          currentLevel: 5,
          effect: '거래 성공률 +50%, 수익 +25%',
          cost: 1000,
          unlockLevel: 5,
          prerequisite: null,
          learnedBy: 1250
        },
        { 
          id: 2, 
          name: '운송 마스터', 
          category: 'transportation',
          description: '이동 속도와 운반 용량을 증가시킵니다',
          maxLevel: 8,
          currentLevel: 3,
          effect: '이동속도 +30%, 운반용량 +40%',
          cost: 800,
          unlockLevel: 3,
          prerequisite: null,
          learnedBy: 890
        },
        { 
          id: 3, 
          name: '협상 전문가', 
          category: 'social',
          description: '상인과의 협상에서 유리한 조건을 얻습니다',
          maxLevel: 5,
          currentLevel: 2,
          effect: '가격 할인 +20%, 특별 거래 확률 +15%',
          cost: 1500,
          unlockLevel: 8,
          prerequisite: '거래 달인',
          learnedBy: 456
        },
        { 
          id: 4, 
          name: '시장 분석가', 
          category: 'analysis',
          description: '시장 동향을 파악하고 최적의 거래 타이밍을 찾습니다',
          maxLevel: 7,
          currentLevel: 4,
          effect: '시장 정보 정확도 +60%, 가격 예측 +40%',
          cost: 2000,
          unlockLevel: 12,
          prerequisite: '협상 전문가',
          learnedBy: 234
        },
        { 
          id: 5, 
          name: '리스크 매니저', 
          category: 'management',
          description: '거래 위험을 최소화하고 손실을 방지합니다',
          maxLevel: 6,
          currentLevel: 1,
          effect: '손실 방지 +25%, 보험료 할인 +30%',
          cost: 2500,
          unlockLevel: 15,
          prerequisite: '시장 분석가',
          learnedBy: 89
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const filteredSkills = skills.filter(skill => {
    const matchesSearch = skill.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         skill.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || skill.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const sortedSkills = [...filteredSkills].sort((a, b) => {
    switch (sortBy) {
      case 'cost':
        return b.cost - a.cost;
      case 'level':
        return b.currentLevel - a.currentLevel;
      case 'maxLevel':
        return b.maxLevel - a.maxLevel;
      case 'popularity':
        return b.learnedBy - a.learnedBy;
      case 'unlockLevel':
        return a.unlockLevel - b.unlockLevel;
      default:
        return a.name.localeCompare(b.name);
    }
  });

  const getCategoryIcon = (category) => {
    switch(category) {
      case 'trading': return '💰';
      case 'transportation': return '🚚';
      case 'social': return '🤝';
      case 'analysis': return '📊';
      case 'management': return '📈';
      default: return '⚡';
    }
  };

  const getSkillLevelColor = (currentLevel, maxLevel) => {
    const percentage = (currentLevel / maxLevel) * 100;
    if (percentage >= 80) return '#10B981'; // Green
    if (percentage >= 60) return '#3B82F6'; // Blue  
    if (percentage >= 40) return '#F59E0B'; // Yellow
    if (percentage >= 20) return '#EF4444'; // Red
    return '#6B7280'; // Gray
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
        <h2>⚡ 스킬 관리</h2>
        <p>플레이어 스킬 시스템을 관리하고 조정하세요</p>
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
            placeholder="스킬 이름으로 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="sort-controls">
          <label>카테고리:</label>
          <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
            <option value="all">전체</option>
            <option value="trading">거래</option>
            <option value="transportation">운송</option>
            <option value="social">사회</option>
            <option value="analysis">분석</option>
            <option value="management">관리</option>
          </select>
        </div>
        <div className="sort-controls">
          <label>정렬:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="name">이름</option>
            <option value="cost">비용</option>
            <option value="level">현재 레벨</option>
            <option value="maxLevel">최대 레벨</option>
            <option value="popularity">인기도</option>
            <option value="unlockLevel">해금 레벨</option>
          </select>
        </div>
      </div>

      <div className="data-table">
        <table>
          <thead>
            <tr>
              <th>스킬</th>
              <th>카테고리</th>
              <th>레벨</th>
              <th>효과</th>
              <th>비용</th>
              <th>해금 레벨</th>
              <th>선행 스킬</th>
              <th>학습자 수</th>
              <th>액션</th>
            </tr>
          </thead>
          <tbody>
            {sortedSkills.map(skill => (
              <tr key={skill.id}>
                <td className="player-name">
                  {getCategoryIcon(skill.category)} {skill.name}
                  <div className="description-cell">{skill.description}</div>
                </td>
                <td>
                  <span className="category-badge">
                    {skill.category === 'trading' ? '거래' :
                     skill.category === 'transportation' ? '운송' :
                     skill.category === 'social' ? '사회' :
                     skill.category === 'analysis' ? '분석' :
                     skill.category === 'management' ? '관리' : skill.category}
                  </span>
                </td>
                <td>
                  <div className="skill-level">
                    <div className="level-bar">
                      <div 
                        className="level-fill" 
                        style={{
                          width: `${(skill.currentLevel / skill.maxLevel) * 100}%`,
                          background: getSkillLevelColor(skill.currentLevel, skill.maxLevel)
                        }}
                      ></div>
                    </div>
                    <span className="level-text">{skill.currentLevel}/{skill.maxLevel}</span>
                  </div>
                </td>
                <td className="effect-cell">{skill.effect}</td>
                <td className="money-cell">
                  {skill.cost.toLocaleString()}SP
                </td>
                <td>
                  <span className="level-badge">Lv.{skill.unlockLevel}</span>
                </td>
                <td className="prerequisite-cell">
                  {skill.prerequisite || '-'}
                </td>
                <td>{skill.learnedBy.toLocaleString()}명</td>
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
        <span>총 {sortedSkills.length}개의 스킬</span>
      </div>
    </div>
  );
};

export default SkillManagement;