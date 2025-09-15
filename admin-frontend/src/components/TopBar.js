import React from 'react';
import './TopBar.css';

const TopBar = ({ onThemeToggle, theme, onSidebarToggle }) => {
  return (
    <header className="topbar">
      <div className="topbar-left">
        <button className="sidebar-toggle" onClick={onSidebarToggle}>
          <span className="hamburger-line"></span>
          <span className="hamburger-line"></span>
          <span className="hamburger-line"></span>
        </button>
        <h1 className="page-title">Way Game Admin</h1>
      </div>

      <div className="topbar-right">
        <div className="quick-stats">
          <div className="quick-stat">
            <span className="stat-label">서버 상태</span>
            <span className="stat-value status-online">온라인</span>
          </div>
          <div className="quick-stat">
            <span className="stat-label">활성 사용자</span>
            <span className="stat-value">127</span>
          </div>
        </div>

        <button 
          className="theme-toggle"
          onClick={onThemeToggle}
          title={`${theme === 'light' ? '다크' : '라이트'} 모드로 전환`}
        >
          {theme === 'light' ? '🌙' : '☀️'}
        </button>

        <div className="admin-profile">
          <div className="profile-info">
            <span className="admin-name">관리자</span>
            <span className="admin-role">Super Admin</span>
          </div>
          <div className="profile-avatar">
            👤
          </div>
        </div>
      </div>
    </header>
  );
};

export default TopBar;