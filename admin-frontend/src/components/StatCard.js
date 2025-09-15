import React from 'react';
import './StatCard.css';

const StatCard = ({ title, value, icon, trend, color }) => {
  const trendDirection = trend > 0 ? 'up' : trend < 0 ? 'down' : 'neutral';
  const trendIcon = trend > 0 ? '↗️' : trend < 0 ? '↘️' : '→';

  return (
    <div className="stat-card">
      <div className="stat-header">
        <div className="stat-icon" style={{ backgroundColor: color }}>
          {icon}
        </div>
        <div className={`stat-trend trend-${trendDirection}`}>
          <span className="trend-icon">{trendIcon}</span>
          <span className="trend-value">{Math.abs(trend)}%</span>
        </div>
      </div>
      
      <div className="stat-content">
        <h3 className="stat-title">{title}</h3>
        <p className="stat-value">{value}</p>
      </div>

      <div className="stat-footer">
        <span className="stat-description">
          {trendDirection === 'up' ? '증가' : trendDirection === 'down' ? '감소' : '변화없음'}
          (지난 주 대비)
        </span>
      </div>
    </div>
  );
};

export default StatCard;