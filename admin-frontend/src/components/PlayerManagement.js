import React, { useState, useEffect } from 'react';
import './Management.css';
import adminAPI from '../services/AdminAPI';

const PlayerManagement = () => {
  const [players, setPlayers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');

  useEffect(() => {
    fetchPlayers();
  }, []);

  const fetchPlayers = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const playersData = await adminAPI.getPlayers();
      console.log('Players data from server:', playersData);
      
      if (playersData && Array.isArray(playersData)) {
        setPlayers(playersData);
      } else {
        // 서버에서 데이터를 가져올 수 없으면 목업 데이터 사용
        console.warn('서버에서 플레이어 데이터를 가져올 수 없습니다. 목업 데이터를 사용합니다.');
        setPlayers([
          { id: 1, name: '김게이머', level: 15, money: 2500000, currentLicense: 3, totalTrades: 45, lastActive: '2024-01-15 14:30' },
          { id: 2, name: '박트레이더', level: 22, money: 8900000, currentLicense: 4, totalTrades: 127, lastActive: '2024-01-15 16:20' },
          { id: 3, name: '이상인', level: 8, money: 450000, currentLicense: 2, totalTrades: 12, lastActive: '2024-01-14 19:45' },
          { id: 4, name: '최부자', level: 35, money: 25000000, currentLicense: 5, totalTrades: 289, lastActive: '2024-01-15 18:10' }
        ]);
      }
      
    } catch (error) {
      console.error('플레이어 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setPlayers([
        { id: 1, name: '김게이머', level: 15, money: 2500000, currentLicense: 3, totalTrades: 45, lastActive: '2024-01-15 14:30' },
        { id: 2, name: '박트레이더', level: 22, money: 8900000, currentLicense: 4, totalTrades: 127, lastActive: '2024-01-15 16:20' },
        { id: 3, name: '이상인', level: 8, money: 450000, currentLicense: 2, totalTrades: 12, lastActive: '2024-01-14 19:45' },
        { id: 4, name: '최부자', level: 35, money: 25000000, currentLicense: 5, totalTrades: 289, lastActive: '2024-01-15 18:10' }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const filteredPlayers = players.filter(player =>
    player.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const sortedPlayers = [...filteredPlayers].sort((a, b) => {
    switch (sortBy) {
      case 'level':
        return b.level - a.level;
      case 'money':
        return b.money - a.money;
      case 'trades':
        return b.totalTrades - a.totalTrades;
      default:
        return a.name.localeCompare(b.name);
    }
  });

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
        <h2>👥 플레이어 관리</h2>
        <p>등록된 플레이어들을 관리하고 모니터링하세요</p>
      </div>

      <div className="management-controls">
        <div className="search-bar">
          <input
            type="text"
            placeholder="플레이어 이름으로 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="sort-controls">
          <label>정렬:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="name">이름</option>
            <option value="level">레벨</option>
            <option value="money">보유금</option>
            <option value="trades">거래횟수</option>
          </select>
        </div>
      </div>

      <div className="data-table">
        <table>
          <thead>
            <tr>
              <th>이름</th>
              <th>레벨</th>
              <th>라이센스</th>
              <th>보유금</th>
              <th>거래횟수</th>
              <th>최종 접속</th>
              <th>액션</th>
            </tr>
          </thead>
          <tbody>
            {sortedPlayers.map(player => (
              <tr key={player.id}>
                <td className="player-name">{player.name}</td>
                <td>
                  <span className="level-badge">Lv.{player.level}</span>
                </td>
                <td>
                  <span className="license-badge">Level {player.currentLicense}</span>
                </td>
                <td className="money-cell">
                  {player.money.toLocaleString()}원
                </td>
                <td>{player.totalTrades}회</td>
                <td className="time-cell">{player.lastActive}</td>
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
        <span>총 {sortedPlayers.length}명의 플레이어</span>
      </div>
    </div>
  );
};

export default PlayerManagement;