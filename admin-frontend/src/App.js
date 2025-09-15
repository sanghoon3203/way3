import React, { useState, useEffect } from 'react';
import './App.css';
import Sidebar from './components/Sidebar';
import Dashboard from './components/Dashboard';
import PlayerManagement from './components/PlayerManagement';
import MerchantManagement from './components/MerchantManagement';
import ItemManagement from './components/ItemManagement';
import QuestManagement from './components/QuestManagement';
import SkillManagement from './components/SkillManagement';
import Monitoring from './components/Monitoring';
import TopBar from './components/TopBar';

function App() {
  const [currentPage, setCurrentPage] = useState('dashboard');
  const [theme, setTheme] = useState('light');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light');
  };

  const renderCurrentPage = () => {
    switch(currentPage) {
      case 'dashboard':
        return <Dashboard />;
      case 'players':
        return <PlayerManagement />;
      case 'merchants':
        return <MerchantManagement />;
      case 'items':
        return <ItemManagement />;
      case 'quests':
        return <QuestManagement />;
      case 'skills':
        return <SkillManagement />;
      case 'monitoring':
        return <Monitoring />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className={`app ${theme}`}>
      <Sidebar 
        currentPage={currentPage}
        onPageChange={setCurrentPage}
        isOpen={sidebarOpen}
        onToggle={() => setSidebarOpen(!sidebarOpen)}
      />
      <div className={`main-content ${sidebarOpen ? 'sidebar-open' : 'sidebar-closed'}`}>
        <TopBar 
          onThemeToggle={toggleTheme}
          theme={theme}
          onSidebarToggle={() => setSidebarOpen(!sidebarOpen)}
        />
        <div className="content">
          {renderCurrentPage()}
        </div>
      </div>
    </div>
  );
}

export default App;
