# Way3 Documentation

Complete technical documentation for the Way3 location-based trading game project.

## 📚 Documentation Index

### Core Documentation (Read in Order)

1. **[00_PROJECT_OVERVIEW.md](00_PROJECT_OVERVIEW.md)** - Start here!
   - High-level project overview
   - Tech stack and dependencies
   - Key features and gameplay mechanics
   - Project structure

2. **[01_ARCHITECTURE.md](01_ARCHITECTURE.md)** - System Design
   - Client architecture patterns (MVVM)
   - Component interactions and data flow
   - Design patterns used throughout
   - State management approach

3. **[02_PLAYER_SYSTEM.md](02_PLAYER_SYSTEM.md)** - Player Model Deep Dive
   - Modular 5-component player system
   - PlayerCore, Stats, Inventory, Relationships, Achievements
   - Cross-component operations
   - Data persistence

4. **[03_GAME_FEATURES.md](03_GAME_FEATURES.md)** - Gameplay Mechanics
   - Trading system (buy/sell/exchange)
   - Progression (level, license, skills)
   - Achievement system
   - Location-based features
   - Auction system

5. **[04_NETWORK_REALTIME.md](04_NETWORK_REALTIME.md)** - Networking
   - Socket.IO integration
   - Real-time multiplayer features
   - Connection management
   - Event handling (location, trade, chat)

6. **[05_UI_DESIGN_SYSTEM.md](05_UI_DESIGN_SYSTEM.md)** - UI/UX Design
   - Cyberpunk design system
   - Color palette and typography
   - Reusable components
   - Styling guidelines

7. **[06_DATA_MODELS.md](06_DATA_MODELS.md)** - Data Reference
   - Complete enum reference
   - Data structures and models
   - API response formats
   - Codable implementations

8. **[07_DEVELOPER_GUIDE.md](07_DEVELOPER_GUIDE.md)** - Development Setup
   - Project setup instructions
   - Development workflow
   - Testing strategies
   - Build and deployment
   - Troubleshooting

### Backend Documentation

9. **[08_SERVER_ARCHITECTURE.md](08_SERVER_ARCHITECTURE.md)** - Server System
   - Node.js/Express backend architecture
   - Database schema (SQLite)
   - Socket.IO server setup
   - Admin panel features
   - Security and monitoring

10. **[09_SERVER_API_REFERENCE.md](09_SERVER_API_REFERENCE.md)** - API Endpoints
    - Complete REST API reference
    - Authentication flows
    - Request/response formats
    - WebSocket events
    - Error codes and rate limits

### Specialized Documentation

The following documents cover specific features or implementation details:

- **[story-system-design.md](story-system-design.md)** - Story/dialogue system architecture
- **[Asset_Checklist_Seoyena.md](Asset_Checklist_Seoyena.md)** - Asset checklist for merchant Seoyena
- **[MOV_Migration_Summary.md](MOV_Migration_Summary.md)** - Video file migration summary
- **[MerchantDetailView_Cyberpunk_Enhancement.md](MerchantDetailView_Cyberpunk_Enhancement.md)** - UI enhancement notes
- **[MerchantHeroView_Implementation_Summary.md](MerchantHeroView_Implementation_Summary.md)** - Hero view implementation
- **[MerchantHeroView_VisualNovel_Redesign.md](MerchantHeroView_VisualNovel_Redesign.md)** - Visual novel style design
- **[Midjourney_Background_Prompts.md](Midjourney_Background_Prompts.md)** - AI art generation prompts
- **[iPhone_Layout_Validation.md](iPhone_Layout_Validation.md)** - Layout testing notes

## 🎯 Quick Start Guide

### For New Developers

1. Read **00_PROJECT_OVERVIEW.md** to understand the project
2. Follow **07_DEVELOPER_GUIDE.md** to set up your environment
3. Review **01_ARCHITECTURE.md** to understand the system design
4. Explore **02_PLAYER_SYSTEM.md** and **03_GAME_FEATURES.md** for game logic
5. Reference **09_SERVER_API_REFERENCE.md** when integrating with the backend

### For Designers

1. **05_UI_DESIGN_SYSTEM.md** - Complete design system reference
2. **MerchantHeroView_VisualNovel_Redesign.md** - Visual novel UI patterns
3. **Midjourney_Background_Prompts.md** - Art generation guidelines

### For Backend Developers

1. **08_SERVER_ARCHITECTURE.md** - Server system overview
2. **09_SERVER_API_REFERENCE.md** - API endpoint specifications
3. **04_NETWORK_REALTIME.md** - Client-side Socket.IO integration

### For QA/Testers

1. **00_PROJECT_OVERVIEW.md** - Feature overview
2. **03_GAME_FEATURES.md** - Detailed gameplay mechanics
3. **07_DEVELOPER_GUIDE.md** - Setup and testing instructions

## 📖 Documentation Standards

### File Naming Convention

- **Numbered docs (00-09)**: Core documentation, read sequentially
- **Descriptive names**: Feature-specific or implementation-specific docs
- **Markdown format**: All documentation uses `.md` format for version control

### Documentation Style

- **Code examples**: Real code snippets from the actual codebase
- **Diagrams**: ASCII art for system architecture visualization
- **Cross-references**: Links to related documentation sections
- **Version info**: Last updated dates and version numbers included

## 🔄 Keeping Documentation Updated

### When to Update Documentation

- **New features**: Update relevant feature documentation
- **Architecture changes**: Update architecture and design pattern docs
- **API changes**: Update API reference immediately
- **Breaking changes**: Update all affected documentation sections

### Documentation Ownership

| Document | Primary Owner | Update Frequency |
|----------|--------------|------------------|
| 00-03 | iOS Team | When features change |
| 04 | iOS + Backend | When network protocol changes |
| 05 | Design Team | When design system evolves |
| 06 | iOS Team | When data models change |
| 07 | DevOps | When setup/build process changes |
| 08-09 | Backend Team | When server architecture/APIs change |

## 🤝 Contributing to Documentation

1. Keep documentation **up-to-date** with code changes
2. Use **clear, concise** language
3. Include **code examples** when explaining concepts
4. Add **cross-references** to related documentation
5. Update **README.md** when adding new documentation files

## 📊 Documentation Coverage

**Core Systems**: ✅ Complete
- iOS Client Architecture
- Player System
- Game Features
- Networking
- UI/UX Design
- Data Models
- Backend Server
- API Reference

**Development Workflows**: ✅ Complete
- Setup and Installation
- Development Guidelines
- Testing Strategies
- Deployment Procedures

**Specialized Features**: ⚠️ Partial
- Story system (documented separately)
- Merchant character system (partial)
- Asset management (checklists available)

## 🔗 External Resources

### Official Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [MapboxMaps for iOS](https://docs.mapbox.com/ios/maps/guides/)
- [Socket.IO Client](https://socket.io/docs/v4/client-api/)
- [Node.js Documentation](https://nodejs.org/docs/)
- [Express.js Guide](https://expressjs.com/)

### Design Resources

- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## 📅 Documentation Changelog

### 2025-10-05
- ✨ **Created comprehensive documentation suite (00-09)**
- 🗑️ **Removed outdated architecture documents**
  - Removed `Way3_Client_Analysis_and_Plan.md` (replaced by 00-03)
  - Removed `Way3_iOS_Architecture_Guide.md` (replaced by 01)
  - Removed `Way3_iOS_Onboarding.md` (replaced by 07)
- 🧹 **Cleaned up screenshot files** (moved to separate assets)
- 📝 **Added README.md** for documentation navigation

### Previous Versions
- Various feature-specific documentation created during development
- Story system design documentation
- Merchant UI implementation notes

---

**Project**: Way3 - Location-Based Trading Game
**Platform**: iOS 16.0+ / Node.js 18+
**Documentation Version**: 1.0
**Last Updated**: 2025-10-05
