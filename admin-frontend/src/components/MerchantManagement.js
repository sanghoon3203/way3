import React, { useState, useEffect } from 'react';
import './Management.css';
import adminAPI from '../services/AdminAPI';

const MerchantManagement = () => {
  const [merchants, setMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');

  useEffect(() => {
    fetchMerchants();
  }, []);

  const fetchMerchants = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const merchantsData = await adminAPI.getMerchants();
      console.log('Merchants data from server:', merchantsData);
      
      if (merchantsData && Array.isArray(merchantsData)) {
        setMerchants(merchantsData);
      } else {
        // 서버에서 데이터를 가져올 수 없으면 목업 데이터 사용
        console.warn('서버에서 상인 데이터를 가져올 수 없습니다. 목업 데이터를 사용합니다.');
        setMerchants([
          { 
            id: 1, 
            name: '박상인', 
            level: 5, 
            region: '강남구', 
            totalSales: 15000000, 
            commission: 1500000,
            status: 'active',
            lastActive: '2024-01-15 18:30' 
          },
          { 
            id: 2, 
            name: '김장사', 
            level: 8, 
            region: '서초구', 
            totalSales: 28000000, 
            commission: 2800000,
            status: 'active',
            lastActive: '2024-01-15 17:15' 
          },
          { 
            id: 3, 
            name: '이판매', 
            level: 3, 
            region: '마포구', 
            totalSales: 8500000, 
            commission: 850000,
            status: 'inactive',
            lastActive: '2024-01-14 14:20' 
          },
          { 
            id: 4, 
            name: '최거래', 
            level: 12, 
            region: '송파구', 
            totalSales: 45000000, 
            commission: 4500000,
            status: 'active',
            lastActive: '2024-01-15 19:45' 
          }
        ]);
      }
      
    } catch (error) {
      console.error('상인 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setMerchants([
        { 
          id: 1, 
          name: '박상인', 
          level: 5, 
          region: '강남구', 
          totalSales: 15000000, 
          commission: 1500000,
          status: 'active',
          lastActive: '2024-01-15 18:30' 
        },
        { 
          id: 2, 
          name: '김장사', 
          level: 8, 
          region: '서초구', 
          totalSales: 28000000, 
          commission: 2800000,
          status: 'active',
          lastActive: '2024-01-15 17:15' 
        },
        { 
          id: 3, 
          name: '이판매', 
          level: 3, 
          region: '마포구', 
          totalSales: 8500000, 
          commission: 850000,
          status: 'inactive',
          lastActive: '2024-01-14 14:20' 
        },
        { 
          id: 4, 
          name: '최거래', 
          level: 12, 
          region: '송파구', 
          totalSales: 45000000, 
          commission: 4500000,
          status: 'active',
          lastActive: '2024-01-15 19:45' 
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const filteredMerchants = merchants.filter(merchant =>
    merchant.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    merchant.region.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const sortedMerchants = [...filteredMerchants].sort((a, b) => {
    switch (sortBy) {
      case 'level':
        return b.level - a.level;
      case 'sales':
        return b.totalSales - a.totalSales;
      case 'region':
        return a.region.localeCompare(b.region);
      case 'status':
        return a.status.localeCompare(b.status);
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
        <h2>🏪 상인 관리</h2>
        <p>등록된 상인들을 관리하고 매출을 모니터링하세요</p>
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
            placeholder="상인 이름 또는 지역으로 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="sort-controls">
          <label>정렬:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="name">이름</option>
            <option value="level">레벨</option>
            <option value="sales">매출</option>
            <option value="region">지역</option>
            <option value="status">상태</option>
          </select>
        </div>
      </div>

      <div className="data-table">
        <table>
          <thead>
            <tr>
              <th>이름</th>
              <th>레벨</th>
              <th>지역</th>
              <th>총 매출</th>
              <th>수수료</th>
              <th>상태</th>
              <th>최종 접속</th>
              <th>액션</th>
            </tr>
          </thead>
          <tbody>
            {sortedMerchants.map(merchant => (
              <tr key={merchant.id}>
                <td className="player-name">{merchant.name}</td>
                <td>
                  <span className="level-badge">Lv.{merchant.level}</span>
                </td>
                <td>{merchant.region}</td>
                <td className="money-cell">
                  {merchant.totalSales.toLocaleString()}원
                </td>
                <td className="money-cell">
                  {merchant.commission.toLocaleString()}원
                </td>
                <td>
                  <span className={`status-badge ${merchant.status}`}>
                    {merchant.status === 'active' ? '활성' : '비활성'}
                  </span>
                </td>
                <td className="time-cell">{merchant.lastActive}</td>
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
        <span>총 {sortedMerchants.length}명의 상인</span>
      </div>
    </div>
  );
};

export default MerchantManagement;