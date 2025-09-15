import React, { useState, useEffect } from 'react';
import './Management.css';
import adminAPI from '../services/AdminAPI';

const ItemManagement = () => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [categoryFilter, setCategoryFilter] = useState('all');

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const itemsData = await adminAPI.getItems();
      console.log('Items data from server:', itemsData);
      
      if (itemsData && Array.isArray(itemsData)) {
        setItems(itemsData);
      } else {
        // 서버에서 데이터를 가져올 수 없으면 목업 데이터 사용
        console.warn('서버에서 아이템 데이터를 가져올 수 없습니다. 목업 데이터를 사용합니다.');
        setItems([
          { 
            id: 1, 
            name: '빨간 포션', 
            category: 'consumable',
            price: 100,
            description: 'HP를 50 회복시켜주는 포션',
            rarity: 'common',
            stock: 150,
            totalSold: 2500
          },
          { 
            id: 2, 
            name: '강철 검', 
            category: 'weapon',
            price: 1000,
            description: '단단한 강철로 만든 검',
            rarity: 'uncommon',
            stock: 25,
            totalSold: 180
          },
          { 
            id: 3, 
            name: '가죽 갑옷', 
            category: 'armor',
            price: 800,
            description: '기본적인 보호막을 제공하는 가죽 갑옷',
            rarity: 'common',
            stock: 40,
            totalSold: 320
          },
          { 
            id: 4, 
            name: '마나 크리스탈', 
            category: 'consumable',
            price: 250,
            description: 'MP를 100 회복시켜주는 크리스탈',
            rarity: 'rare',
            stock: 75,
            totalSold: 890
          },
          { 
            id: 5, 
            name: '전설의 반지', 
            category: 'accessory',
            price: 5000,
            description: '모든 능력치를 상승시켜주는 전설적인 반지',
            rarity: 'legendary',
            stock: 3,
            totalSold: 12
          }
        ]);
      }
      
    } catch (error) {
      console.error('아이템 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setItems([
        { 
          id: 1, 
          name: '빨간 포션', 
          category: 'consumable',
          price: 100,
          description: 'HP를 50 회복시켜주는 포션',
          rarity: 'common',
          stock: 150,
          totalSold: 2500
        },
        { 
          id: 2, 
          name: '강철 검', 
          category: 'weapon',
          price: 1000,
          description: '단단한 강철로 만든 검',
          rarity: 'uncommon',
          stock: 25,
          totalSold: 180
        },
        { 
          id: 3, 
          name: '가죽 갑옷', 
          category: 'armor',
          price: 800,
          description: '기본적인 보호막을 제공하는 가죽 갑옷',
          rarity: 'common',
          stock: 40,
          totalSold: 320
        },
        { 
          id: 4, 
          name: '마나 크리스탈', 
          category: 'consumable',
          price: 250,
          description: 'MP를 100 회복시켜주는 크리스탈',
          rarity: 'rare',
          stock: 75,
          totalSold: 890
        },
        { 
          id: 5, 
          name: '전설의 반지', 
          category: 'accessory',
          price: 5000,
          description: '모든 능력치를 상승시켜주는 전설적인 반지',
          rarity: 'legendary',
          stock: 3,
          totalSold: 12
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const filteredItems = items.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const sortedItems = [...filteredItems].sort((a, b) => {
    switch (sortBy) {
      case 'price':
        return b.price - a.price;
      case 'stock':
        return b.stock - a.stock;
      case 'sold':
        return b.totalSold - a.totalSold;
      case 'category':
        return a.category.localeCompare(b.category);
      case 'rarity':
        const rarityOrder = { 'common': 1, 'uncommon': 2, 'rare': 3, 'epic': 4, 'legendary': 5 };
        return (rarityOrder[b.rarity] || 0) - (rarityOrder[a.rarity] || 0);
      default:
        return a.name.localeCompare(b.name);
    }
  });

  const getRarityBadgeClass = (rarity) => {
    switch(rarity) {
      case 'common': return 'rarity-common';
      case 'uncommon': return 'rarity-uncommon';
      case 'rare': return 'rarity-rare';
      case 'epic': return 'rarity-epic';
      case 'legendary': return 'rarity-legendary';
      default: return 'rarity-common';
    }
  };

  const getCategoryIcon = (category) => {
    switch(category) {
      case 'weapon': return '⚔️';
      case 'armor': return '🛡️';
      case 'consumable': return '🧪';
      case 'accessory': return '💍';
      default: return '📦';
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
        <h2>📦 아이템 관리</h2>
        <p>게임 내 아이템들의 가격과 속성을 관리하세요</p>
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
            placeholder="아이템 이름으로 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="sort-controls">
          <label>카테고리:</label>
          <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
            <option value="all">전체</option>
            <option value="weapon">무기</option>
            <option value="armor">방어구</option>
            <option value="consumable">소모품</option>
            <option value="accessory">액세서리</option>
          </select>
        </div>
        <div className="sort-controls">
          <label>정렬:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="name">이름</option>
            <option value="price">가격</option>
            <option value="stock">재고</option>
            <option value="sold">판매량</option>
            <option value="category">카테고리</option>
            <option value="rarity">희귀도</option>
          </select>
        </div>
      </div>

      <div className="data-table">
        <table>
          <thead>
            <tr>
              <th>아이템</th>
              <th>카테고리</th>
              <th>가격</th>
              <th>희귀도</th>
              <th>재고</th>
              <th>총 판매량</th>
              <th>설명</th>
              <th>액션</th>
            </tr>
          </thead>
          <tbody>
            {sortedItems.map(item => (
              <tr key={item.id}>
                <td className="player-name">
                  {getCategoryIcon(item.category)} {item.name}
                </td>
                <td>
                  <span className="category-badge">
                    {item.category === 'weapon' ? '무기' :
                     item.category === 'armor' ? '방어구' :
                     item.category === 'consumable' ? '소모품' :
                     item.category === 'accessory' ? '액세서리' : item.category}
                  </span>
                </td>
                <td className="money-cell">
                  {item.price.toLocaleString()}골드
                </td>
                <td>
                  <span className={`rarity-badge ${getRarityBadgeClass(item.rarity)}`}>
                    {item.rarity === 'common' ? '일반' :
                     item.rarity === 'uncommon' ? '고급' :
                     item.rarity === 'rare' ? '희귀' :
                     item.rarity === 'epic' ? '영웅' :
                     item.rarity === 'legendary' ? '전설' : item.rarity}
                  </span>
                </td>
                <td className={item.stock < 10 ? 'low-stock' : ''}>{item.stock}개</td>
                <td>{item.totalSold.toLocaleString()}개</td>
                <td className="description-cell">{item.description}</td>
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
        <span>총 {sortedItems.length}개의 아이템</span>
      </div>
    </div>
  );
};

export default ItemManagement;