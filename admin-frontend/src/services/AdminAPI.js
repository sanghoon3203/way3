// API 서비스 클래스
class AdminAPI {
  constructor() {
    this.baseURL = process.env.REACT_APP_API_URL || 'http://localhost:4000';
    this.adminPath = '/admin';
  }

  // 공통 fetch 함수
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${this.adminPath}${endpoint}`;
    
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    };

    try {
      const response = await fetch(url, defaultOptions);
      
      // HTML 응답인 경우 (기존 어드민 라우트)
      if (response.headers.get('content-type')?.includes('text/html')) {
        const html = await response.text();
        return this.parseHTMLData(html, endpoint);
      }
      
      // JSON 응답인 경우
      if (response.headers.get('content-type')?.includes('application/json')) {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
      }
      
      throw new Error('Unsupported response type');
    } catch (error) {
      console.error(`API request failed for ${endpoint}:`, error);
      throw error;
    }
  }

  // HTML에서 데이터 파싱 (기존 어드민 페이지용)
  parseHTMLData(html, endpoint) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');
    
    if (endpoint === '') {
      // 대시보드 데이터 파싱
      return this.parseDashboardHTML(doc);
    } else if (endpoint === '/players') {
      // 플레이어 데이터 파싱
      return this.parsePlayersHTML(doc);
    }
    
    return null;
  }

  // 대시보드 HTML 파싱
  parseDashboardHTML(doc) {
    const statCards = doc.querySelectorAll('.stat-card');
    const stats = {};
    
    statCards.forEach(card => {
      const label = card.querySelector('.stat-label')?.textContent.trim();
      const value = card.querySelector('.stat-value')?.textContent.trim();
      
      if (label && value) {
        switch(label) {
          case '총 플레이어':
            stats.totalPlayers = parseInt(value) || 0;
            break;
          case '오늘 거래 횟수':
            stats.dailyTrades = parseInt(value) || 0;
            break;
          case '오늘 총 거래량':
            stats.dailyRevenue = parseInt(value.replace(/[^\d]/g, '')) || 0;
            break;
          case '활성 상인':
            stats.activeMerchants = parseInt(value) || 0;
            break;
        }
      }
    });
    
    return {
      ...stats,
      serverStatus: 'running',
      serverUptime: Math.round(Date.now() / 1000) // 임시값
    };
  }

  // 플레이어 HTML 파싱
  parsePlayersHTML(doc) {
    const rows = doc.querySelectorAll('tbody tr');
    const players = [];
    
    rows.forEach(row => {
      const cells = row.querySelectorAll('td');
      if (cells.length >= 6) {
        players.push({
          id: players.length + 1,
          name: cells[0]?.textContent.trim(),
          level: parseInt(cells[1]?.textContent.replace('Lv.', '')) || 0,
          currentLicense: parseInt(cells[2]?.textContent.replace('Level ', '')) || 0,
          money: parseInt(cells[3]?.textContent.replace(/[^\d]/g, '')) || 0,
          totalTrades: parseInt(cells[4]?.textContent.replace('회', '')) || 0,
          lastActive: cells[5]?.textContent.trim()
        });
      }
    });
    
    return players;
  }

  // API 메서드들
  async getDashboardData() {
    return await this.request('');
  }

  async getPlayers(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/players?${queryString}` : '/players';
    return await this.request(endpoint);
  }

  async getMerchants(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/crud/merchants?${queryString}` : '/crud/merchants';
    return await this.request(endpoint);
  }

  async getItems(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/crud/items?${queryString}` : '/crud/items';
    return await this.request(endpoint);
  }

  async getMonitoringData() {
    return await this.request('/monitoring');
  }

  async getQuests(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/quests?${queryString}` : '/quests';
    return await this.request(endpoint);
  }

  async getSkills(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/skills?${queryString}` : '/skills';
    return await this.request(endpoint);
  }

  // CRUD 작업
  async createEntity(entity, data) {
    return await this.request(`/crud/${entity}`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateEntity(entity, id, data) {
    return await this.request(`/crud/${entity}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteEntity(entity, id) {
    return await this.request(`/crud/${entity}/${id}`, {
      method: 'DELETE',
    });
  }

  // 헬스체크
  async getServerHealth() {
    try {
      const response = await fetch(`${this.baseURL}/health`);
      if (response.ok) {
        return await response.json();
      }
      throw new Error('Health check failed');
    } catch (error) {
      console.error('Health check error:', error);
      return { status: 'error', message: error.message };
    }
  }
}

// 싱글톤 인스턴스
const adminAPI = new AdminAPI();
export default adminAPI;