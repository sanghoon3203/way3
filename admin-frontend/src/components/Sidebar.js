import React from 'react';
import './Sidebar.css';

const Sidebar = ({ currentPage, onPageChange, isOpen, onToggle }) => {
  const menuItems = [
    { id: 'dashboard', icon: '📊', label: '대시보드', path: '/admin' },
    { id: 'players', icon: '👥', label: '플레이어 관리', path: '/admin/players' },
    { id: 'merchants', icon: '🏪', label: '상인 관리', path: '/admin/merchants' },
    { id: 'items', icon: '📦', label: '아이템 관리', path: '/admin/items' },
    { id: 'quests', icon: '🎯', label: '퀘스트 관리', path: '/admin/quests' },
    { id: 'skills', icon: '⚡', label: '스킬 관리', path: '/admin/skills' },
    { id: 'monitoring', icon: '📈', label: '실시간 모니터링', path: '/admin/monitoring' }
  ];

  return (
    <>
      {/* 모바일 오버레이 */}
      {isOpen && (
        <div className="sidebar-overlay" onClick={onToggle}></div>
      )}
      
      <aside className={`sidebar ${isOpen ? 'open' : 'closed'}`}>
        <div className="sidebar-header">
          <div className="logo">
            <h2>🎮 Way Admin</h2>
          </div>
        </div>
        
        <nav className="sidebar-nav">
          {menuItems.map(item => (
            <button
              key={item.id}
              className={`nav-item ${currentPage === item.id ? 'active' : ''}`}
              onClick={() => onPageChange(item.id)}
              title={item.label}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="server-status">
            <div className="status-indicator online"></div>
            <span>서버 온라인</span>
          </div>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;