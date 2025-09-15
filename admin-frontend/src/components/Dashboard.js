import React, { useState, useEffect } from 'react';
import './Dashboard.css';
import StatCard from './StatCard';
import ChartWidget from './ChartWidget';
import adminAPI from '../services/AdminAPI';

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalPlayers: 0,
    dailyTrades: 0,
    dailyRevenue: 0,
    activeMerchants: 0,
    serverUptime: 0
  });

  const [chartData, setChartData] = useState({
    dailyUsers: [],
    tradeVolume: [],
    revenueChart: []
  });

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // API 호출로 실제 데이터 가져오기
    fetchDashboardData();
    
    // 5초마다 데이터 업데이트
    const interval = setInterval(fetchDashboardData, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 실제 서버 API 호출
      const dashboardData = await adminAPI.getDashboardData();
      console.log('Dashboard data from server:', dashboardData);
      
      // 서버에서 받은 데이터 설정
      if (dashboardData) {
        setStats({
          totalPlayers: dashboardData.totalPlayers || 0,
          dailyTrades: dashboardData.dailyTrades || 0,
          dailyRevenue: dashboardData.dailyRevenue || 0,
          activeMerchants: dashboardData.activeMerchants || 0,
          serverUptime: dashboardData.serverUptime || 0
        });
      }

      // 서버 헬스체크
      const healthData = await adminAPI.getServerHealth();
      if (healthData && healthData.status === 'healthy') {
        setStats(prevStats => ({
          ...prevStats,
          serverUptime: Math.round(healthData.uptime || 0)
        }));
      }

      // 차트 데이터는 임시로 목업 사용 (추후 실제 API 구현 시 교체)
      setChartData({
        dailyUsers: generateMockChartData(7),
        tradeVolume: generateMockChartData(7),
        revenueChart: generateMockChartData(7)
      });
      
    } catch (error) {
      console.error('대시보드 데이터 로딩 실패:', error);
      setError(error.message);
      
      // 에러 발생 시 목업 데이터로 폴백
      setStats({
        totalPlayers: 0,
        dailyTrades: 0,
        dailyRevenue: 0,
        activeMerchants: 0,
        serverUptime: 0
      });
      
      setChartData({
        dailyUsers: generateMockChartData(7),
        tradeVolume: generateMockChartData(7),
        revenueChart: generateMockChartData(7)
      });
    } finally {
      setLoading(false);
    }
  };

  const generateMockChartData = (days) => {
    return Array.from({ length: days }, (_, i) => ({
      date: new Date(Date.now() - (days - 1 - i) * 24 * 60 * 60 * 1000).toLocaleDateString(),
      value: Math.floor(Math.random() * 100) + 50
    }));
  };

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h2>📊 대시보드 개요</h2>
        <p>Way Game의 실시간 통계와 성과를 확인하세요</p>
      </div>

      {/* 통계 카드들 */}
      <div className="stats-grid">
        <StatCard
          title="총 플레이어"
          value={stats.totalPlayers.toLocaleString()}
          icon="👥"
          trend={5.2}
          color="#4f46e5"
        />
        <StatCard
          title="오늘 거래"
          value={stats.dailyTrades.toLocaleString()}
          icon="💰"
          trend={12.3}
          color="#059669"
        />
        <StatCard
          title="일일 수익"
          value={`${(stats.dailyRevenue / 10000).toFixed(1)}만원`}
          icon="💎"
          trend={-2.1}
          color="#dc2626"
        />
        <StatCard
          title="활성 상인"
          value={stats.activeMerchants.toLocaleString()}
          icon="🏪"
          trend={8.7}
          color="#7c3aed"
        />
      </div>

      {/* 차트 위젯들 */}
      <div className="charts-grid">
        <ChartWidget
          title="일일 활성 사용자"
          data={chartData.dailyUsers}
          type="line"
          color="#4f46e5"
        />
        <ChartWidget
          title="거래량 추이"
          data={chartData.tradeVolume}
          type="bar"
          color="#059669"
        />
        <ChartWidget
          title="수익 추이"
          data={chartData.revenueChart}
          type="area"
          color="#dc2626"
        />
      </div>

      {/* 최근 활동 */}
      <div className="recent-activities">
        <h3>📈 최근 활동</h3>
        <div className="activities-list">
          <div className="activity-item">
            <div className="activity-icon">👤</div>
            <div className="activity-content">
              <span className="activity-text">새로운 플레이어 '김게이머'가 가입했습니다</span>
              <span className="activity-time">2분 전</span>
            </div>
          </div>
          <div className="activity-item">
            <div className="activity-icon">💰</div>
            <div className="activity-content">
              <span className="activity-text">대형 거래가 완료되었습니다 (500만원)</span>
              <span className="activity-time">5분 전</span>
            </div>
          </div>
          <div className="activity-item">
            <div className="activity-icon">🏪</div>
            <div className="activity-content">
              <span className="activity-text">새 상인 '박상인'이 강남구에 개점했습니다</span>
              <span className="activity-time">12분 전</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;