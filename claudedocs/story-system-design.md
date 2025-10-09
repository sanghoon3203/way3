# Story-Driven Dialogue System - Comprehensive Design

## Executive Summary

This document outlines the complete system design for implementing main story progression through merchant conversations in the Way3 location-based trading game, following the masterplan in `way3/Story/masterplan.md`.

**Design Philosophy:**
- **Reuse Existing Infrastructure**: Minimal new systems, maximum leverage of current quest/dialogue architecture
- **Additive Changes Only**: No breaking modifications to existing functionality
- **Server Authoritative**: Client validates, server decides
- **Content/Code Separation**: Independent deployment of narrative and technical features

---

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Story Content Layer                        │
│         Markdown Files → Export Script → JSON Assets         │
│   (Story/MainStory/, MerchantSideQuests/)                   │
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    Database Layer                            │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ quest_templates│  │merchant_dialogues│  │ story_nodes  │ │
│  │ +dialogue type │  │ +trigger_condition│  │   (NEW)      │ │
│  └────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐│
│  │        player_story_progress (NEW)                       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                   Server API Layer                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  QuestService: Add "dialogue" quest type                ││
│  │  StoryService (NEW): Story progression logic            ││
│  │  Enhanced Dialogue API: Quest context filtering         ││
│  │  Quest Progress Handler: Dialogue event support         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  Client Data Layer                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  StoryManager (NEW): State tracking + sync              ││
│  │  DialogueDataManager: Quest-aware dialogue fetching     ││
│  │  GameManager: Story system integration                  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                   Client UI Layer                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  MerchantDetailView: Story dialogue display             ││
│  │  QuestView: Story quest tracking                        ││
│  │  MapView: Story merchant markers                        ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Database Schema Design

### ⚠️ MIGRATION REQUIRED: Conflict Resolution Updates

**Critical Changes to Avoid Server-Client Conflicts:**

1. **merchants table**: Add story system columns
2. **quest_templates table**: Add story quest support columns
3. **New tables**: story_nodes, player_story_progress
4. **quest progress handler**: Support dialogue objective type

---

### 2.1 Merchants Table Migration

**🔴 CONFLICT #1, #4, #6: Add story role and node tracking**

```sql
-- Migration: Add story system support to merchants table
ALTER TABLE merchants ADD COLUMN story_role TEXT CHECK(story_role IN ('main', 'side', 'vendor_only'));
ALTER TABLE merchants ADD COLUMN initial_story_node TEXT;
ALTER TABLE merchants ADD COLUMN has_active_story INTEGER DEFAULT 0; -- Boolean flag for quick filtering

CREATE INDEX idx_merchants_story_role ON merchants(story_role) WHERE story_role IS NOT NULL;
CREATE INDEX idx_merchants_has_story ON merchants(has_active_story) WHERE has_active_story = 1;

-- Update existing merchants (example)
UPDATE merchants SET story_role = 'vendor_only', has_active_story = 0 WHERE story_role IS NULL;
```

**Updated Server Response (`/api/merchants/:id`):**
```javascript
// src/routes/api/merchants.js - Enhanced response
{
  id: merchant.id,
  name: merchant.name,
  // ... existing fields ...

  // 🆕 Story system fields
  storyRole: merchant.story_role,           // 'main' | 'side' | 'vendor_only' | null
  hasActiveStory: merchant.has_active_story === 1,  // Boolean
  initialStoryNode: merchant.initial_story_node     // String | null
}
```

---

### 2.2 Enhanced Quest Templates

**🔴 CONFLICT #2: Add story quest support**

**Migration:**
```sql
-- Add story quest columns to quest_templates
ALTER TABLE quest_templates ADD COLUMN story_node_id TEXT;
ALTER TABLE quest_templates ADD COLUMN is_story_quest INTEGER DEFAULT 0;

CREATE INDEX idx_quest_templates_story ON quest_templates(is_story_quest) WHERE is_story_quest = 1;
CREATE INDEX idx_quest_templates_node ON quest_templates(story_node_id) WHERE story_node_id IS NOT NULL;
```

**New Quest Objective Type - "dialogue":**
```javascript
// 🔴 CONFLICT #5: Quest progress handler must support this
// In QuestService.js - getQuestTypes()
dialogue: {
  label: '대화',
  icon: '💬',
  description: '상인과 특정 대화를 완료하는 퀘스트',
  objectiveTemplate: {
    type: 'dialogue',
    target_node: '',     // Required: Story node ID (e.g., "ch1_node_005")
    merchantId: '',      // Required: Target merchant ID
    description: ''      // Required: Display text
  }
}
```

**Example Main Story Quest:**
```json
{
  "id": "uuid-1",
  "name": "마리와의 첫 만남",
  "description": "마포의 염력사 마리를 찾아가 인사를 나누세요",
  "category": "main_story",
  "type": "dialogue",
  "level_requirement": 1,
  "required_license": 0,
  "prerequisites": [],
  "story_node_id": "ch1_node_001",
  "is_story_quest": 1,
  "objectives": [
    {
      "type": "dialogue",
      "target_node": "ch1_node_001",
      "merchantId": "mariapple",
      "description": "마리와 대화하기"
    }
  ],
  "rewards": {
    "experience": 100,
    "money": 1000,
    "trustPoints": 10
  },
  "auto_complete": true,
  "sort_order": 1
}
```

### 2.3 Enhanced Merchant Dialogues (Optional Extension)

**⚠️ Note**: This table extension is OPTIONAL. Story dialogues can be managed entirely through `story_nodes` table.

**Existing Table:** `merchant_dialogues`

**If extending for backward compatibility:**
```sql
-- Optional: Add story node reference
ALTER TABLE merchant_dialogues ADD COLUMN story_node_id TEXT;
CREATE INDEX idx_merchant_dialogues_story ON merchant_dialogues(story_node_id) WHERE story_node_id IS NOT NULL;
```

### 2.4 Story Nodes Table (NEW)

**Purpose**: Store story dialogue content and branching logic

```sql
CREATE TABLE story_nodes (
  id TEXT PRIMARY KEY,
  node_type TEXT NOT NULL CHECK(node_type IN ('dialogue', 'decision', 'quest_gate')),
  merchant_id TEXT REFERENCES merchants(id),
  location_id TEXT,                                 -- Optional: specific location requirement
  content TEXT NOT NULL,                            -- JSON: dialogue content
  choices TEXT,                                     -- JSON: player choices (for decision nodes)
  prerequisites TEXT,                               -- JSON: requirements to access node
  next_nodes TEXT,                                  -- JSON: next possible nodes
  rewards TEXT,                                     -- JSON: rewards for completing node
  metadata TEXT,                                    -- JSON: chapter info, tags, etc.
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_story_nodes_merchant ON story_nodes(merchant_id);
CREATE INDEX idx_story_nodes_type ON story_nodes(node_type);
```

**content JSON Schema:**
```json
{
  "speaker": "마리",
  "text": "처음 뵙겠습니다. 저는 염력사 마리입니다.",
  "emotion": "friendly",
  "portrait": "merchant_mari_01.png"
}
```

**choices JSON Schema (for decision nodes):**
```json
[
  {
    "id": "accept",
    "text": "어떤 물건인가요?",
    "next_node": "ch1_node_002"
  },
  {
    "id": "decline",
    "text": "지금은 시간이 없습니다",
    "next_node": null
  }
]
```

**prerequisites JSON Schema:**
```json
{
  "level_min": 3,
  "location": "seoul_gangnam",
  "story_flags": {
    "ch1_started": false
  },
  "quests_completed": ["tutorial_quest_001"]
}
```

### 2.5 Player Story Progress Table (NEW)

```sql
CREATE TABLE player_story_progress (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id),
  current_node_id TEXT,                          -- Active story node
  completed_nodes TEXT DEFAULT '[]',             -- JSON array of completed nodeIds
  story_variables TEXT DEFAULT '{}',             -- JSON for branching state
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(player_id)
);

CREATE INDEX idx_player_story_player ON player_story_progress(player_id);
```

**story_variables Schema:**
```json
{
  "choices": {                         // Track player choices
    "phase1_ch1_scene2": "option_A"
  },
  "relationships": {                   // Track story-specific relationship states
    "mari": "friendly"
  },
  "flags": {                           // Story flags for branching
    "mari_side_unlocked": true
  }
}
```

---

## 3. Server-Side Implementation

### ⚠️ Critical API Changes to Prevent Conflicts

**Summary of Server Changes:**
1. **Merchants API**: Add story fields to response
2. **New Story API**: `/api/merchants/:id/story` (separate from `/dialogues`)
3. **Quest Progress Handler**: Support `dialogue` objective type
4. **StoryService**: New service for story progression logic

---

### 3.1 Merchants API Enhancement

**🔴 CONFLICT #1, #4: Update response to include story fields**

**File:** `way-server/src/routes/api/merchants.js`

```javascript
// In GET /api/merchants/:merchantId route (line ~194)
res.json({
  success: true,
  data: {
    id: merchant.id,
    name: merchant.name,
    // ... existing fields ...

    // 🆕 Story system fields
    storyRole: merchant.story_role,                    // 'main' | 'side' | 'vendor_only' | null
    hasActiveStory: merchant.has_active_story === 1,   // Boolean
    initialStoryNode: merchant.initial_story_node,     // String | null

    // ... rest of response ...
  }
});
```

**In GET /api/merchants/nearby route (line ~92):**
```javascript
return {
  id: merchant.id,
  name: merchant.name,
  // ... existing fields ...

  // 🆕 Story marker indicators
  hasActiveStory: merchant.has_active_story === 1,
  storyRole: merchant.story_role,

  // ... rest of response ...
};
```

---

### 3.2 New Story Dialogue API

**🔴 CONFLICT #4: Separate endpoint to avoid collision with existing `/dialogues`**

**File:** `way-server/src/routes/api/merchants.js`

```javascript
/**
 * 🆕 Get story dialogue for merchant
 * GET /api/merchants/:merchantId/story
 *
 * IMPORTANT: This is SEPARATE from /dialogues endpoint
 * /dialogues: Returns general merchant conversation text
 * /story: Returns story node based dialogue with choices
 */
router.get('/:merchantId/story', authenticateToken, async (req, res) => {
  try {
    const { merchantId } = req.params;
    const playerId = req.user.playerId;

    // Check if merchant has story role
    const merchant = await DatabaseManager.get(`
      SELECT id, name, story_role, initial_story_node, has_active_story
      FROM merchants
      WHERE id = ? AND is_active = 1
    `, [merchantId]);

    if (!merchant || !merchant.has_active_story) {
      return res.status(404).json({
        success: false,
        error: 'No active story for this merchant'
      });
    }

    // Get player's story progress
    const StoryService = require('../../services/game/StoryService');
    const progress = await StoryService.getPlayerStoryProgress(playerId);

    // Determine which node to show
    let nodeId;
    if (progress.currentNodeId && progress.currentNodeId.includes(merchantId)) {
      nodeId = progress.currentNodeId;
    } else {
      nodeId = merchant.initial_story_node;
    }

    if (!nodeId) {
      return res.status(404).json({
        success: false,
        error: 'No story node available'
      });
    }

    // Get story node
    const node = await StoryService.getStoryNode(nodeId);

    // Check prerequisites
    const canAccess = await StoryService.checkPrerequisites(playerId, node.prerequisites);
    if (!canAccess.success) {
      return res.json({
        success: false,
        error: 'PREREQUISITES_NOT_MET',
        missing: canAccess.missing,
        fallbackDialogue: "아직 그 이야기를 나눌 때가 아닌 것 같습니다."
      });
    }

    // Filter available choices
    const availableChoices = await StoryService.filterChoices(playerId, node.choices);

    res.json({
      success: true,
      data: {
        node: {
          id: node.id,
          type: node.node_type,
          content: JSON.parse(node.content),
          choices: availableChoices
        },
        merchantName: merchant.name
      }
    });

  } catch (error) {
    logger.error('Story dialogue fetch failed:', error);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
});
```

---

### 3.3 Quest Progress Handler Extension

**🔴 CONFLICT #2, #5: Add dialogue objective support**

**File:** `way-server/src/routes/game/quests.js`

```javascript
/**
 * 🔄 Enhanced quest progress handler
 * POST /game/quests/progress
 */
router.post('/progress', authenticateToken, async (req, res) => {
  try {
    const playerId = req.user.playerId;
    const { actionType, actionData } = req.body;

    // 🆕 Handle dialogue completion
    if (actionType === 'dialogue_completed') {
      const { nodeId, merchantId } = actionData;

      // Find active quests with dialogue objectives
      const activeQuests = await DatabaseManager.all(`
        SELECT pq.*, qt.objectives
        FROM player_quests pq
        JOIN quest_templates qt ON pq.quest_template_id = qt.id
        WHERE pq.player_id = ? AND pq.status = 'active'
      `, [playerId]);

      for (const quest of activeQuests) {
        const objectives = JSON.parse(quest.objectives || '[]');
        const progress = JSON.parse(quest.progress || '{}');
        let updated = false;

        objectives.forEach((obj, index) => {
          if (obj.type === 'dialogue' &&
              obj.target_node === nodeId &&
              obj.merchantId === merchantId) {
            progress[`objective_${index}`] = 1;
            updated = true;
          }
        });

        if (updated) {
          await DatabaseManager.run(`
            UPDATE player_quests
            SET progress = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
          `, [JSON.stringify(progress), quest.id]);

          // Check if quest is now complete
          const allComplete = objectives.every((_, i) => progress[`objective_${i}`] === 1);
          if (allComplete) {
            await DatabaseManager.run(`
              UPDATE player_quests
              SET status = 'completed', completed_at = CURRENT_TIMESTAMP
              WHERE id = ?
            `, [quest.id]);
          }
        }
      }

      return res.json({
        success: true,
        message: 'Dialogue objective progress updated'
      });
    }

    // ... existing action types (collect, trade, etc.) ...

  } catch (error) {
    logger.error('Quest progress update failed:', error);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
});
```

### 3.2 StoryService (NEW)

**File:** `way-server/src/services/game/StoryService.js`

```javascript
// 📁 src/services/game/StoryService.js - Story progression logic
const DatabaseManager = require('../../database/DatabaseManager');
const logger = require('../../config/logger');
const { randomUUID } = require('crypto');

class StoryService {

  /**
   * Get player's current story progress
   */
  static async getPlayerStoryProgress(playerId) {
    let progress = await DatabaseManager.get(`
      SELECT * FROM player_story_progress WHERE player_id = ?
    `, [playerId]);

    if (!progress) {
      // Initialize story progress for new player
      progress = await this.initializePlayerStory(playerId);
    }

    return {
      currentNodeId: progress.current_node_id,
      completedNodes: JSON.parse(progress.completed_nodes || '[]'),
      storyVariables: JSON.parse(progress.story_variables || '{}'),
      lastUpdated: progress.last_updated
    };
  }

  /**
   * Initialize story progress for new player
   */
  static async initializePlayerStory(playerId) {
    const id = randomUUID();

    await DatabaseManager.run(`
      INSERT INTO player_story_progress (
        id, player_id, current_node_id, completed_nodes, story_variables
      ) VALUES (?, ?, NULL, '[]', '{}')
    `, [id, playerId]);

    return await DatabaseManager.get(`
      SELECT * FROM player_story_progress WHERE id = ?
    `, [id]);
  }

  /**
   * Advance story to next node
   */
  static async advanceStoryNode(playerId, nodeId, choiceId = null) {
    // Get current progress
    const progress = await this.getPlayerStoryProgress(playerId);
    const completedNodes = progress.completedNodes;
    const storyVariables = progress.storyVariables;

    // Get node details
    const node = await DatabaseManager.get(`
      SELECT * FROM story_nodes WHERE node_id = ?
    `, [nodeId]);

    if (!node) {
      throw new Error(`Story node not found: ${nodeId}`);
    }

    // Check prerequisites
    const canProgress = await this.checkNodePrerequisites(playerId, nodeId);
    if (!canProgress) {
      throw new Error('Prerequisites not met for this story node');
    }

    // Mark node as completed
    if (!completedNodes.includes(nodeId)) {
      completedNodes.push(nodeId);
    }

    // Record choice if provided
    if (choiceId) {
      if (!storyVariables.choices) storyVariables.choices = {};
      storyVariables.choices[nodeId] = choiceId;
    }

    // Determine next nodes
    const nextNodes = JSON.parse(node.next_nodes || '[]');
    const availableNextNodes = await this.filterAvailableNodes(
      playerId,
      nextNodes,
      node.branch_condition
    );

    // Update progress
    const nextNodeId = availableNextNodes.length > 0 ? availableNextNodes[0] : null;

    await DatabaseManager.run(`
      UPDATE player_story_progress
      SET current_node_id = ?,
          completed_nodes = ?,
          story_variables = ?,
          last_updated = CURRENT_TIMESTAMP
      WHERE player_id = ?
    `, [
      nextNodeId,
      JSON.stringify(completedNodes),
      JSON.stringify(storyVariables),
      playerId
    ]);

    logger.info('Story progress advanced', {
      playerId,
      completedNode: nodeId,
      nextNode: nextNodeId
    });

    return {
      completedNode: nodeId,
      nextNodes: availableNextNodes,
      currentNode: nextNodeId
    };
  }

  /**
   * Check if player meets prerequisites for a node
   */
  static async checkNodePrerequisites(playerId, nodeId) {
    const node = await DatabaseManager.get(`
      SELECT * FROM story_nodes WHERE node_id = ?
    `, [nodeId]);

    if (!node) return false;

    const progress = await this.getPlayerStoryProgress(playerId);
    const completedNodes = progress.completedNodes;

    // Check if associated quest prerequisites are met
    if (node.quest_id) {
      const quest = await DatabaseManager.get(`
        SELECT prerequisites FROM quest_templates WHERE id = ?
      `, [node.quest_id]);

      if (quest) {
        const prerequisites = JSON.parse(quest.prerequisites || '[]');
        for (const prereqQuestId of prerequisites) {
          const completed = await DatabaseManager.get(`
            SELECT id FROM player_quests
            WHERE player_id = ? AND quest_template_id = ? AND status = 'completed'
          `, [playerId, prereqQuestId]);

          if (!completed) return false;
        }
      }
    }

    // Check node-level prerequisites (previous nodes)
    // This would be stored in node metadata if needed

    return true;
  }

  /**
   * Filter available next nodes based on branch conditions
   */
  static async filterAvailableNodes(playerId, nextNodes, branchCondition) {
    if (!branchCondition) {
      return nextNodes; // No branching, return all next nodes
    }

    const condition = JSON.parse(branchCondition);
    const progress = await this.getPlayerStoryProgress(playerId);

    // Filter based on condition type
    switch (condition.type) {
      case 'choice':
        // Choice-based branching handled by choiceId in advanceStoryNode
        return nextNodes;

      case 'inventory':
        // Check if player has required items
        const hasItems = await this.checkPlayerInventory(
          playerId,
          condition.requiredItems || []
        );
        return hasItems ? nextNodes : [];

      case 'relationship':
        // Check relationship level with merchant
        const hasRelationship = await this.checkMerchantRelationship(
          playerId,
          condition.merchantId,
          condition.requiredRelationship || 0
        );
        return hasRelationship ? nextNodes : [];

      default:
        return nextNodes;
    }
  }

  /**
   * Get available story nodes for player (unlocked but not completed)
   */
  static async getAvailableStoryNodes(playerId) {
    const progress = await this.getPlayerStoryProgress(playerId);
    const completedNodes = progress.completedNodes;

    // Get all active story nodes
    const allNodes = await DatabaseManager.all(`
      SELECT * FROM story_nodes
      ORDER BY stage, node_order
    `);

    const availableNodes = [];

    for (const node of allNodes) {
      // Skip completed nodes
      if (completedNodes.includes(node.node_id)) continue;

      // Check prerequisites
      const canAccess = await this.checkNodePrerequisites(playerId, node.node_id);
      if (canAccess) {
        availableNodes.push(node);
      }
    }

    return availableNodes;
  }

  // Helper methods
  static async checkPlayerInventory(playerId, requiredItemIds) {
    // Implementation depends on your inventory system
    return true; // Placeholder
  }

  static async checkMerchantRelationship(playerId, merchantId, requiredLevel) {
    const relationship = await DatabaseManager.get(`
      SELECT friendship_points FROM merchant_relationships
      WHERE player_id = ? AND merchant_id = ?
    `, [playerId, merchantId]);

    return relationship && relationship.friendship_points >= requiredLevel;
  }
}

module.exports = StoryService;
```

### 3.3 Enhanced Dialogue API

**File:** `way-server/src/routes/api/merchants.js`

**Enhancement to GET /api/merchants/:merchantId/dialogues:**

```javascript
/**
 * Enhanced dialogue endpoint with quest context support
 * GET /api/merchants/:merchantId/dialogues?triggerType=&questId=&stage=&nodeId=
 */
router.get('/:merchantId/dialogues', async (req, res) => {
  try {
    const { merchantId } = req.params;
    const { triggerType, questId, stage, nodeId } = req.query;
    const playerId = req.user?.playerId || null;

    // Verify merchant exists
    const merchant = await DatabaseManager.get(`
      SELECT id, name, merchant_type, personality
      FROM merchants
      WHERE id = ? AND is_active = 1
    `, [merchantId]);

    if (!merchant) {
      return res.status(404).json({
        success: false,
        error: '상인을 찾을 수 없습니다'
      });
    }

    // Build query with quest context filtering
    const params = [merchantId];
    let dialogueQuery = `
      SELECT id, trigger_type, dialogue_text, dialogue_order,
             emotion, trigger_condition, updated_at
      FROM merchant_dialogues
      WHERE merchant_id = ? AND is_active = 1
    `;

    // Filter by trigger type
    if (triggerType) {
      dialogueQuery += ' AND trigger_type = ?';
      params.push(triggerType);
    }

    // Filter by quest context (NEW)
    if (questId) {
      dialogueQuery += ` AND (
        trigger_condition IS NULL OR
        json_extract(trigger_condition, '$.questId') = ?
      )`;
      params.push(questId);
    }

    if (stage) {
      dialogueQuery += ` AND (
        trigger_condition IS NULL OR
        json_extract(trigger_condition, '$.stage') = ? OR
        json_extract(trigger_condition, '$.stage') IS NULL
      )`;
      params.push(parseInt(stage));
    }

    if (nodeId) {
      dialogueQuery += ` AND (
        trigger_condition IS NULL OR
        json_extract(trigger_condition, '$.nodeId') = ?
      )`;
      params.push(nodeId);
    }

    dialogueQuery += ' ORDER BY dialogue_order, created_at';

    const rows = await DatabaseManager.all(dialogueQuery, params);

    // Organize dialogues by trigger type
    const dialogueBuckets = {
      greeting: [],
      trading: [],
      goodbye: [],
      relationship: [],
      special: [],
      main_story: [],  // NEW
      side_story: []   // NEW
    };

    let nodeMetadata = null;

    for (const row of rows) {
      const category = mapTriggerToCategory(row.trigger_type);
      if (dialogueBuckets[category]) {
        dialogueBuckets[category].push(row.dialogue_text);
      }

      // Extract node metadata if available
      if (row.trigger_condition && (triggerType === 'main_story' || triggerType === 'side_story')) {
        try {
          nodeMetadata = JSON.parse(row.trigger_condition);
        } catch (e) {
          logger.warn('Failed to parse trigger_condition', {
            merchantId,
            dialogueId: row.id
          });
        }
      }
    }

    // Fallback to generic dialogues if no story-specific found
    const fallbackDialogues = generateFallbackDialogues(merchant);
    for (const category of Object.keys(dialogueBuckets)) {
      if (dialogueBuckets[category].length === 0) {
        dialogueBuckets[category] = fallbackDialogues[category] || [];
      }
    }

    const responsePayload = {
      merchantId: merchant.id,
      merchantName: merchant.name,
      personality: merchant.personality || 'neutral',
      dialogues: dialogueBuckets,
      nodeMetadata: nodeMetadata, // NEW: Quest context metadata
      lastUpdated: new Date().toISOString()
    };

    // Log dialogue fetch with quest context
    if (playerId) {
      try {
        await DatabaseManager.run(`
          INSERT INTO merchant_dialogue_logs (
            id, player_id, merchant_id, interaction_type,
            message_text, merchant_emotion, metadata
          ) VALUES (?, ?, ?, 'load_dialogues', NULL, NULL, ?)
        `, [
          randomUUID(),
          playerId,
          merchantId,
          JSON.stringify({ questId, stage, nodeId })
        ]);
      } catch (logError) {
        logger.warn('Dialogue log failed', { merchantId, playerId });
      }
    }

    return res.json({
      success: true,
      data: responsePayload
    });

  } catch (error) {
    logger.error('Merchant dialogue fetch failed:', error);
    return res.status(500).json({
      success: false,
      error: '상인 대화를 불러오는 중 오류가 발생했습니다'
    });
  }
});

// Update mapTriggerToCategory to handle story types
function mapTriggerToCategory(triggerType = '') {
  const normalized = triggerType.toLowerCase();

  if (['main_story', 'story', 'quest'].includes(normalized)) {
    return 'main_story';
  }
  if (['side_story', 'side_quest'].includes(normalized)) {
    return 'side_story';
  }
  // ... existing mappings
  return 'special';
}
```

### 3.4 Quest Progress Handler Enhancement

**File:** `way-server/src/routes/game/quests.js`

**Enhancement to POST /game/quests/progress:**

```javascript
/**
 * Enhanced quest progress endpoint with dialogue event support
 * POST /game/quests/progress
 * Body: { actionType, actionData } or { eventType, eventData }
 */
router.post('/progress', async (req, res) => {
  try {
    const playerId = req.user.playerId;
    const { actionType, actionData, eventType, eventData } = req.body;

    const type = actionType || eventType;
    const data = actionData || eventData;

    if (!type || !data) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_REQUEST', message: '요청 데이터가 유효하지 않습니다' }
      });
    }

    // Handle dialogue progress (NEW)
    if (type === 'dialogue') {
      return await handleDialogueProgress(playerId, data, res);
    }

    // ... existing progress handlers for other types

  } catch (error) {
    logger.error('Quest progress update failed:', error);
    res.status(500).json({
      success: false,
      error: { code: 'INTERNAL_SERVER_ERROR', message: '서버 오류가 발생했습니다' }
    });
  }
});

/**
 * Handle dialogue-based quest progression (NEW)
 */
async function handleDialogueProgress(playerId, eventData, res) {
  const { merchantId, nodeId, dialogueId, choiceId, questId } = eventData;

  if (!merchantId || !nodeId) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_DATA', message: 'merchantId and nodeId are required' }
    });
  }

  // Find active quests with matching dialogue objectives
  const activeQuests = await DatabaseManager.all(`
    SELECT pq.*, qt.objectives, qt.name, qt.auto_complete
    FROM player_quests pq
    JOIN quest_templates qt ON pq.quest_template_id = qt.id
    WHERE pq.player_id = ? AND pq.status = 'active'
  `, [playerId]);

  const updatedQuests = [];
  const completedQuests = [];

  for (const quest of activeQuests) {
    const objectives = JSON.parse(quest.objectives || '[]');
    const progress = JSON.parse(quest.progress || '{}');
    let questUpdated = false;

    // Check each objective
    objectives.forEach((objective, index) => {
      if (objective.type === 'dialogue') {
        // Match by merchantId and nodeId
        if (objective.merchantId === merchantId && objective.nodeId === nodeId) {
          const progressKey = `objective_${index}`;

          // Check if already completed
          if (!progress[progressKey] || progress[progressKey] < 1) {
            progress[progressKey] = 1;
            questUpdated = true;

            logger.info('Dialogue objective completed', {
              playerId,
              questId: quest.quest_template_id,
              merchantId,
              nodeId
            });
          }
        }
      }
    });

    if (questUpdated) {
      // Check if all objectives completed
      const allComplete = objectives.every((_, index) => {
        const progressKey = `objective_${index}`;
        return progress[progressKey] >= 1;
      });

      if (allComplete && quest.auto_complete) {
        // Complete quest automatically
        await DatabaseManager.run(`
          UPDATE player_quests
          SET status = 'completed',
              progress = ?,
              completed_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `, [JSON.stringify(progress), quest.id]);

        completedQuests.push({
          questId: quest.quest_template_id,
          title: quest.name
        });

        // Advance story if this was a story quest
        const StoryService = require('../../services/game/StoryService');
        try {
          await StoryService.advanceStoryNode(playerId, nodeId, choiceId);
        } catch (storyError) {
          logger.warn('Story advancement failed', { playerId, nodeId, error: storyError.message });
        }

      } else {
        // Update progress only
        await DatabaseManager.run(`
          UPDATE player_quests
          SET progress = ?
          WHERE id = ?
        `, [JSON.stringify(progress), quest.id]);
      }

      updatedQuests.push({
        questId: quest.quest_template_id,
        title: quest.name,
        progress: progress
      });
    }
  }

  return res.json({
    success: true,
    data: {
      updatedQuests,
      completedQuests,
      message: completedQuests.length > 0
        ? '퀘스트를 완료했습니다!'
        : '진행도가 업데이트되었습니다'
    }
  });
}
```

### 3.5 Story Progress API Routes (NEW)

**File:** `way-server/src/routes/game/story.js` (NEW)

```javascript
// 📁 src/routes/game/story.js - Story progress API routes
const express = require('express');
const { authenticateToken } = require('../../middleware/auth');
const StoryService = require('../../services/game/StoryService');
const logger = require('../../config/logger');

const router = express.Router();
router.use(authenticateToken);

/**
 * Get player's story progress
 * GET /game/story/progress
 */
router.get('/progress', async (req, res) => {
  try {
    const playerId = req.user.playerId;

    const progress = await StoryService.getPlayerStoryProgress(playerId);
    const availableNodes = await StoryService.getAvailableStoryNodes(playerId);

    res.json({
      success: true,
      data: {
        currentNodeId: progress.currentNodeId,
        completedNodes: progress.completedNodes,
        availableNodes: availableNodes.map(node => ({
          nodeId: node.node_id,
          questId: node.quest_id,
          merchantId: node.merchant_id,
          stage: node.stage,
          metadata: JSON.parse(node.metadata || '{}')
        })),
        storyVariables: progress.storyVariables
      }
    });

  } catch (error) {
    logger.error('Story progress fetch failed:', error);
    res.status(500).json({
      success: false,
      error: { code: 'INTERNAL_SERVER_ERROR', message: '서버 오류가 발생했습니다' }
    });
  }
});

/**
 * Advance story progress
 * POST /game/story/progress
 * Body: { nodeId, choiceId }
 */
router.post('/progress', async (req, res) => {
  try {
    const playerId = req.user.playerId;
    const { nodeId, choiceId } = req.body;

    if (!nodeId) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_REQUEST', message: 'nodeId is required' }
      });
    }

    const result = await StoryService.advanceStoryNode(playerId, nodeId, choiceId);

    res.json({
      success: true,
      data: result,
      message: '스토리가 진행되었습니다'
    });

  } catch (error) {
    logger.error('Story advancement failed:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'STORY_ADVANCEMENT_FAILED',
        message: error.message || '스토리 진행 중 오류가 발생했습니다'
      }
    });
  }
});

module.exports = router;
```

**Register route in app.js:**
```javascript
// In way-server/src/app.js
const storyRoutes = require('./routes/game/story');
app.use('/game/story', storyRoutes);
```

---

## 4. Client-Side Implementation

### ⚠️ Critical Swift Model Changes to Prevent Conflicts

**Summary of Client Changes:**
1. **Merchant Model**: Add story fields (storyRole, hasActiveStory, initialStoryNode)
2. **NetworkManager**: Add `/story` endpoint methods
3. **MerchantAnnotationView**: Add story indicator UI overlay
4. **New StoryManager**: Handle story progression state
5. **New DialogueView**: Display story dialogues with choices

---

### 4.1 Enhanced Merchant Model

**🔴 CONFLICT #3, #6: Add story system fields to Swift Merchant model**

**File:** `way3/way3/Models/Merchant.swift`

```swift
// 📁 Models/Merchant.swift - Enhanced with story system
struct Merchant: Identifiable {
    let id: String
    let name: String
    // ... existing fields ...

    // 🆕 Story system fields
    let storyRole: StoryRole?           // Story role classification
    let hasActiveStory: Bool            // Quick check for story availability
    let initialStoryNode: String?       // Entry point story node

    // ... rest of existing fields ...
}

// 🆕 Story Role Enum
enum StoryRole: String, Codable {
    case main = "main"              // Main story merchant
    case side = "side"              // Side story merchant
    case vendorOnly = "vendor_only" // No story content
}

// 🆕 Update ServerMerchantResponse
struct ServerMerchantResponse: Codable {
    let id: String
    let name: String
    // ... existing fields ...

    // 🆕 Story fields from server
    let storyRole: String?
    let hasActiveStory: Bool
    let initialStoryNode: String?
}

// 🆕 Update init(from serverMerchant:)
extension Merchant {
    init(from serverMerchant: ServerMerchantResponse) {
        self.id = serverMerchant.id
        self.name = serverMerchant.name
        // ... existing field mappings ...

        // 🆕 Story field mappings
        self.storyRole = serverMerchant.storyRole.flatMap { StoryRole(rawValue: $0) }
        self.hasActiveStory = serverMerchant.hasActiveStory
        self.initialStoryNode = serverMerchant.initialStoryNode
    }
}
```

---

### 4.2 Enhanced MerchantAnnotationView

**🔴 CONFLICT #6: Add story indicator overlay to map markers**

**File:** `way3/way3/Views/Map/MerchantAnnotationView.swift`

```swift
// 📁 Views/Map/MerchantAnnotationView.swift
struct MerchantAnnotationView: View {
    let merchant: Merchant

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Existing merchant pin
            VStack {
                Image(systemName: merchant.iconName)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(merchant.pinColor)
                    .clipShape(Circle())

                Text(merchant.name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            // 🆕 Story indicator overlay
            if merchant.hasActiveStory {
                Image(systemName: "text.bubble.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 20, height: 20)
                    )
                    .offset(x: 5, y: -5)
            }
        }
    }
}
```

---

### 4.3 Enhanced NetworkManager

**🔴 CONFLICT #4: Add story API methods**

**File:** `way3/way3/Utils/NetworkManager.swift`

```swift
// 📁 Utils/NetworkManager.swift
extension NetworkManager {

    // 🆕 Get story dialogue for merchant
    // IMPORTANT: Uses /story endpoint, NOT /dialogues
    func getStoryDialogue(merchantId: String) async throws -> StoryDialogueResponse {
        let endpoint = "/api/merchants/\(merchantId)/story"

        let response: APIResponse<StoryDialogueResponse> = try await request(
            endpoint: endpoint,
            method: "GET"
        )

        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }

        return data
    }

    // 🆕 Progress story (make choice)
    func progressStory(nodeId: String, choiceId: String) async throws -> StoryProgressResult {
        let endpoint = "/api/story/progress"

        let body: [String: Any] = [
            "nodeId": nodeId,
            "choiceId": choiceId
        ]

        let response: APIResponse<StoryProgressResult> = try await request(
            endpoint: endpoint,
            method: "POST",
            body: body
        )

        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }

        return data
    }

    // 🆕 Notify dialogue completion (for quest objectives)
    func notifyDialogueCompleted(nodeId: String, merchantId: String) async throws {
        let endpoint = "/game/quests/progress"

        let body: [String: Any] = [
            "actionType": "dialogue_completed",
            "actionData": [
                "nodeId": nodeId,
                "merchantId": merchantId
            ]
        ]

        let response: APIResponse<EmptyResponse> = try await request(
            endpoint: endpoint,
            method: "POST",
            body: body
        )

        if !response.success {
            throw NetworkError.requestFailed
        }
    }
}

// 🆕 Response models
struct StoryDialogueResponse: Codable {
    let node: StoryNodeData
    let merchantName: String
}

struct StoryNodeData: Codable {
    let id: String
    let type: String
    let content: StoryContent
    let choices: [StoryChoice]
}

struct StoryContent: Codable {
    let speaker: String
    let text: String
    let emotion: String
    let portrait: String?
}

struct StoryChoice: Codable {
    let id: String
    let text: String
    let nextNode: String?

    enum CodingKeys: String, CodingKey {
        case id, text
        case nextNode = "next_node"
    }
}

struct StoryProgressResult: Codable {
    let rewards: Rewards?
    let nextNode: StoryNodeData?
    let questsStarted: [String]
}

struct Rewards: Codable {
    let exp: Int?
    let reputation: Int?
}
```

---

### 4.4 Story Data Models

**File:** `way3/way3/Models/StoryModels.swift` (NEW)

```swift
// 📁 Models/StoryModels.swift - Story system data models
import Foundation

// MARK: - Story Node
struct StoryNode: Codable, Identifiable {
    let id: String
    let nodeId: String
    let questId: String
    let merchantId: String
    let stage: Int
    let nodeOrder: Int
    let nextNodes: [String]
    let branchCondition: BranchCondition?
    let metadata: StoryMetadata?

    enum CodingKeys: String, CodingKey {
        case id, nodeId, questId, merchantId, stage, nodeOrder, nextNodes
        case branchCondition, metadata
    }
}

// MARK: - Branch Condition
struct BranchCondition: Codable {
    let type: String // "choice", "inventory", "relationship"
    let requiredChoice: String?
    let requiredItems: [String]?
    let requiredRelationship: Int?
}

// MARK: - Story Metadata
struct StoryMetadata: Codable {
    let chapterName: String?
    let sceneName: String?
    let isKeyMoment: Bool?
    let cinematicMode: Bool?
}

// MARK: - Story Progress Response
struct StoryProgressResponse: Codable {
    let currentNodeId: String?
    let completedNodes: [String]
    let availableNodes: [AvailableStoryNode]
    let storyVariables: [String: AnyCodable]

    struct AvailableStoryNode: Codable {
        let nodeId: String
        let questId: String
        let merchantId: String
        let stage: Int
        let metadata: StoryMetadata?
    }
}

// MARK: - Story Advance Response
struct StoryAdvanceResponse: Codable {
    let completedNode: String
    let nextNodes: [String]
    let currentNode: String?
}

// MARK: - Quest Context for Dialogues
struct QuestContext: Codable {
    let questId: String?
    let stage: Int?
    let nodeId: String?

    init(questId: String? = nil, stage: Int? = nil, nodeId: String? = nil) {
        self.questId = questId
        self.stage = stage
        self.nodeId = nodeId
    }
}

// MARK: - Enhanced Dialogue Category
extension DialogueCategory {
    static let mainStory = DialogueCategory(rawValue: "main_story")!
    static let sideStory = DialogueCategory(rawValue: "side_story")!
}

// Helper for dynamic JSON decoding
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        }
    }
}
```

### 4.2 StoryManager

**File:** `way3/way3/Managers/StoryManager.swift` (NEW)

```swift
// 📁 Managers/StoryManager.swift - Story progression manager
import Foundation
import Combine

@MainActor
class StoryManager: ObservableObject {

    // MARK: - Singleton
    static let shared = StoryManager()
    private init() {}

    // MARK: - Published Properties
    @Published var currentNodeId: String?
    @Published var completedNodes: Set<String> = []
    @Published var availableNodes: [StoryProgressResponse.AvailableStoryNode] = []
    @Published var storyVariables: [String: Any] = [:]
    @Published var isLoading = false
    @Published var error: StoryError?

    // MARK: - Dependencies
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var hasActiveStory: Bool {
        return currentNodeId != nil
    }

    var currentStage: Int? {
        return availableNodes.first(where: { $0.nodeId == currentNodeId })?.stage
    }

    // MARK: - Story Progress

    /// Fetch story progress from server
    func fetchStoryProgress() async {
        isLoading = true
        error = nil

        do {
            let response: APIResponse<StoryProgressResponse> = try await networkManager.makeRequest(
                endpoint: "/game/story/progress",
                method: "GET",
                requiresAuth: true
            )

            if response.success, let data = response.data {
                currentNodeId = data.currentNodeId
                completedNodes = Set(data.completedNodes)
                availableNodes = data.availableNodes
                // Convert AnyCodable to native types
                storyVariables = data.storyVariables.compactMapValues { $0.value }
            }

            isLoading = false

        } catch {
            self.error = .fetchFailed(error)
            isLoading = false
        }
    }

    /// Advance story to next node
    func advanceStory(nodeId: String, choiceId: String? = nil) async throws {
        isLoading = true
        error = nil

        do {
            let body: [String: Any] = [
                "nodeId": nodeId,
                "choiceId": choiceId as Any
            ]

            let response: APIResponse<StoryAdvanceResponse> = try await networkManager.makeRequest(
                endpoint: "/game/story/progress",
                method: "POST",
                body: body,
                requiresAuth: true
            )

            if response.success, let data = response.data {
                // Update local state
                completedNodes.insert(data.completedNode)
                currentNodeId = data.currentNode

                // Refresh available nodes
                await fetchStoryProgress()
            }

            isLoading = false

        } catch {
            self.error = .advanceFailed(error)
            isLoading = false
            throw error
        }
    }

    // MARK: - Quest Integration

    /// Check if merchant has active story dialogue
    func hasActiveStoryNode(merchantId: String) -> Bool {
        return availableNodes.contains(where: { $0.merchantId == merchantId })
    }

    /// Get current quest context for merchant
    func getCurrentContext(merchantId: String) -> QuestContext? {
        guard let node = availableNodes.first(where: { $0.merchantId == merchantId }) else {
            return nil
        }

        return QuestContext(
            questId: node.questId,
            stage: node.stage,
            nodeId: node.nodeId
        )
    }

    /// Get all active story quests
    func getActiveStoryQuests(from quests: [QuestData]) -> [QuestData] {
        return quests.filter { quest in
            quest.category == "main_story" && quest.status == "active"
        }
    }

    /// Sync story state with quest completion
    func syncWithQuests(activeQuests: [QuestData]) async {
        // Update story progress based on completed story quests
        for quest in activeQuests where quest.category == "main_story" {
            // Extract nodeId from quest objectives
            if let nodeId = extractNodeId(from: quest) {
                if quest.status == "completed" && !completedNodes.contains(nodeId) {
                    // Quest completed but story not advanced - sync needed
                    try? await advanceStory(nodeId: nodeId)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func extractNodeId(from quest: QuestData) -> String? {
        // Quest objectives may contain dialogue objectives with nodeId
        // This is a simplified extraction - actual implementation depends on objectives structure
        // For now, return nil as objectives structure needs to be defined
        return nil
    }

    /// Check if node is unlocked for player
    func checkNodeUnlocked(nodeId: String) -> Bool {
        return availableNodes.contains(where: { $0.nodeId == nodeId })
    }

    /// Get story metadata for current node
    func getCurrentMetadata() -> StoryMetadata? {
        guard let nodeId = currentNodeId else { return nil }
        return availableNodes.first(where: { $0.nodeId == nodeId })?.metadata
    }

    // MARK: - Cache Management

    func invalidateCache() {
        currentNodeId = nil
        completedNodes.removeAll()
        availableNodes.removeAll()
        storyVariables.removeAll()
    }
}

// MARK: - Story Error
enum StoryError: LocalizedError {
    case fetchFailed(Error)
    case advanceFailed(Error)
    case invalidNode
    case prerequisitesNotMet

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "스토리 진행 상황을 불러오는데 실패했습니다: \(error.localizedDescription)"
        case .advanceFailed(let error):
            return "스토리 진행에 실패했습니다: \(error.localizedDescription)"
        case .invalidNode:
            return "유효하지 않은 스토리 노드입니다"
        case .prerequisitesNotMet:
            return "스토리 진행 조건을 만족하지 않습니다"
        }
    }
}
```

### 4.3 GameManager Integration

**File:** `way3/way3/Managers/GameManager.swift`

**Add StoryManager integration:**

```swift
// In GameManager.swift

@Published var storyManager = StoryManager.shared

// In initialize() method
func initialize() async {
    // ... existing initialization

    // Initialize story system
    await storyManager.fetchStoryProgress()

    // Sync story with quest state
    await storyManager.syncWithQuests(activeQuests: activeQuests)
}

// Add helper method
func refreshStoryData() async {
    await storyManager.fetchStoryProgress()
}
```

### 4.4 Enhanced DialogueDataManager

**File:** `way3/way3/Core/DialogueDataManager.swift`

**Add quest-aware dialogue fetching:**

```swift
// Add to DialogueDataManager class

/// Fetch dialogues with quest context (ENHANCED)
func getDialogue(
    merchantId: String,
    category: DialogueCategory,
    questContext: QuestContext? = nil,
    useAI: Bool = false
) async -> String {
    do {
        // Fetch with quest context if provided
        let dialogueSet = try await fetchDialogues(
            for: merchantId,
            questContext: questContext
        )

        if useAI {
            return await generateAIDialogue(
                dialogueSet: dialogueSet,
                category: category,
                questContext: questContext
            )
        }

        return selectAppropriateDialogue(
            from: dialogueSet,
            category: category
        )
    } catch {
        return getFallbackDialogue(category: category)
    }
}

// Update fetchDialogues to accept quest context
private func fetchDialogues(
    for merchantId: String,
    questContext: QuestContext? = nil
) async throws -> MerchantDialogueSet {
    // Check cache
    let cacheKey = buildCacheKey(merchantId: merchantId, questContext: questContext)
    if let cached = cachedDialogues[cacheKey] {
        return cached
    }

    isLoading = true
    defer { isLoading = false }

    // Build query parameters
    var queryParams: [String: String] = [:]
    if let context = questContext {
        if let questId = context.questId {
            queryParams["questId"] = questId
        }
        if let stage = context.stage {
            queryParams["stage"] = "\(stage)"
        }
        if let nodeId = context.nodeId {
            queryParams["nodeId"] = nodeId
        }
    }

    // Fetch from server with quest context
    let dialogues = try await loadServerDialogues(
        merchantId: merchantId,
        queryParams: queryParams
    )

    cachedDialogues[cacheKey] = dialogues
    return dialogues
}

// Helper to build cache key with context
private func buildCacheKey(merchantId: String, questContext: QuestContext?) -> String {
    guard let context = questContext else {
        return merchantId
    }

    var key = merchantId
    if let questId = context.questId { key += "_\(questId)" }
    if let stage = context.stage { key += "_s\(stage)" }
    if let nodeId = context.nodeId { key += "_\(nodeId)" }

    return key
}

// Update loadServerDialogues to accept query parameters
private func loadServerDialogues(
    merchantId: String,
    queryParams: [String: String] = [:]
) async throws -> MerchantDialogueSet {
    var endpoint = "/merchants/\(merchantId)/dialogues"

    if !queryParams.isEmpty {
        let queryString = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        endpoint += "?\(queryString)"
    }

    let response = try await networkManager.getMerchantDialogues(endpoint: endpoint)

    return MerchantDialogueSet(
        merchantId: merchantId,
        merchantName: response.merchantName,
        dialogues: response.dialogues,
        personality: response.personality,
        lastUpdated: Date()
    )
}
```

### 4.5 Enhanced MerchantDetailViewModel

**File:** `way3/way3/ViewModels/MerchantDetailViewModel.swift`

**Add story-aware dialogue support:**

```swift
// Add to MerchantDetailViewModel class

// MARK: - Story Integration
private var storyManager: StoryManager {
    return gameManager.storyManager
}

/// Load merchant with story context check (ENHANCED)
func loadMerchant(id: String) async {
    guard currentMerchantId != id else { return }

    isLoading = true
    error = nil
    currentMerchantId = id

    do {
        // Parallel load
        async let detail = dataManager.fetchMerchantDetail(merchantId: id)
        async let inventory = dataManager.fetchMerchantInventory(merchantId: id)
        async let relationship = dataManager.fetchMerchantRelationship(merchantId: id)

        let (loadedDetail, loadedInventory, loadedRelationship) = try await (detail, inventory, relationship)

        self.merchantDetail = loadedDetail
        self.inventory = loadedInventory
        self.relationship = loadedRelationship

        // Check for story dialogue first
        if storyManager.hasActiveStoryNode(merchantId: id) {
            await loadStoryDialogue()
        } else {
            startDialogue() // Regular dialogue
        }

        isLoading = false

    } catch {
        self.error = .networkError(error)
        isLoading = false
    }
}

/// Load story-specific dialogue (NEW)
private func loadStoryDialogue() async {
    guard let merchantId = merchantDetail?.id else { return }

    // Get quest context for this merchant
    guard let questContext = storyManager.getCurrentContext(merchantId: merchantId) else {
        startDialogue() // Fallback to regular dialogue
        return
    }

    // Fetch story dialogue
    let dialogue = await dialogueManager.getDialogue(
        merchantId: merchantId,
        category: .mainStory,
        questContext: questContext
    )

    await MainActor.run {
        startTypingAnimation(text: dialogue)
    }
}

/// Complete story dialogue and advance (NEW)
func completeStoryDialogue(choiceId: String? = nil) async {
    guard let merchantId = merchantDetail?.id,
          let questContext = storyManager.getCurrentContext(merchantId: merchantId),
          let nodeId = questContext.nodeId else {
        return
    }

    do {
        // Submit dialogue progress to quest system
        try await submitDialogueProgress(
            merchantId: merchantId,
            nodeId: nodeId,
            choiceId: choiceId
        )

        // Refresh quest data
        await gameManager.refreshQuestsData()

        // Refresh story progress
        await storyManager.fetchStoryProgress()

    } catch {
        self.error = .networkError(error)
    }
}

/// Submit dialogue progress to server (NEW)
private func submitDialogueProgress(
    merchantId: String,
    nodeId: String,
    choiceId: String? = nil
) async throws {
    let body: [String: Any] = [
        "eventType": "dialogue",
        "eventData": [
            "merchantId": merchantId,
            "nodeId": nodeId,
            "choiceId": choiceId as Any
        ]
    ]

    let _: APIResponse<[String: Any]> = try await NetworkManager.shared.makeRequest(
        endpoint: "/game/quests/progress",
        method: "POST",
        body: body,
        requiresAuth: true
    )
}

/// Check if current interaction is story-related (NEW)
var isStoryInteraction: Bool {
    guard let merchantId = merchantDetail?.id else { return false }
    return storyManager.hasActiveStoryNode(merchantId: merchantId)
}

/// Get current story metadata for UI (NEW)
var currentStoryMetadata: StoryMetadata? {
    return storyManager.getCurrentMetadata()
}
```

---

## 5. Story Export Tooling

### 5.1 Export Script

**File:** `way-server/scripts/story/export_story_assets.js` (NEW)

```javascript
// 📁 scripts/story/export_story_assets.js - Convert markdown to JSON assets
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);
const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);
const mkdir = promisify(fs.mkdir);

// Configuration
const STORY_SOURCE_DIR = path.join(__dirname, '../../Story');
const OUTPUT_DIR = path.join(__dirname, '../../src/database/merchant_data/story');
const VERSION = 'v1';

// Output structure
const storyGraph = {
  nodes: [],
  version: VERSION,
  generatedAt: new Date().toISOString()
};

const merchantDialogues = {};
const quests = [];
const validationReport = {
  errors: [],
  warnings: [],
  stats: {}
};

/**
 * Main export function
 */
async function exportStoryAssets() {
  console.log('🚀 Starting story asset export...\n');

  try {
    // Create output directory
    const versionDir = path.join(OUTPUT_DIR, VERSION);
    await mkdir(versionDir, { recursive: true });
    await mkdir(path.join(versionDir, 'merchantDialogues'), { recursive: true });

    // Process main story
    console.log('📖 Processing main story...');
    const mainStoryDir = path.join(STORY_SOURCE_DIR, 'MainStory');
    await traverseStoryDirectory(mainStoryDir, 'main_story');

    // Process side quests
    console.log('🎯 Processing side quests...');
    const sideQuestDir = path.join(STORY_SOURCE_DIR, 'MerchantSideQuests');
    if (fs.existsSync(sideQuestDir)) {
      await traverseStoryDirectory(sideQuestDir, 'side_quest');
    }

    // Validate references
    console.log('\n🔍 Validating references...');
    await validateReferences();

    // Write output files
    console.log('\n💾 Writing output files...');
    await writeOutputFiles(versionDir);

    // Print summary
    printSummary();

    console.log('\n✅ Story export completed successfully!');

  } catch (error) {
    console.error('\n❌ Export failed:', error);
    process.exit(1);
  }
}

/**
 * Traverse story directory and process markdown files
 */
async function traverseStoryDirectory(dir, category) {
  if (!fs.existsSync(dir)) {
    validationReport.warnings.push(`Directory not found: ${dir}`);
    return;
  }

  const entries = await readdir(dir);

  for (const entry of entries) {
    const fullPath = path.join(dir, entry);
    const stats = await stat(fullPath);

    if (stats.isDirectory()) {
      await traverseStoryDirectory(fullPath, category);
    } else if (entry.endsWith('.md')) {
      await processMarkdownFile(fullPath, category);
    }
  }
}

/**
 * Process individual markdown file
 */
async function processMarkdownFile(filePath, category) {
  console.log(`  Processing: ${path.basename(filePath)}`);

  try {
    const content = await readFile(filePath, 'utf-8');
    const { frontmatter, body } = parseMarkdown(content);

    if (!frontmatter.nodeId) {
      validationReport.errors.push(`Missing nodeId in ${filePath}`);
      return;
    }

    if (!frontmatter.merchantId) {
      validationReport.errors.push(`Missing merchantId in ${filePath}`);
      return;
    }

    // Create story node
    const node = {
      id: `node_${frontmatter.nodeId}`,
      nodeId: frontmatter.nodeId,
      questId: frontmatter.questId || null,
      merchantId: frontmatter.merchantId,
      stage: frontmatter.stage || 1,
      nodeOrder: frontmatter.nodeOrder || 0,
      nextNodes: frontmatter.nextNodes || [],
      branchCondition: frontmatter.branchCondition || null,
      metadata: {
        chapterName: frontmatter.chapterName || null,
        sceneName: frontmatter.sceneName || null,
        isKeyMoment: frontmatter.isKeyMoment || false
      }
    };

    storyGraph.nodes.push(node);

    // Extract dialogues
    const dialogues = extractDialogues(body);
    if (!merchantDialogues[frontmatter.merchantId]) {
      merchantDialogues[frontmatter.merchantId] = {
        greeting: [],
        trading: [],
        goodbye: [],
        relationship: [],
        special: [],
        main_story: [],
        side_story: []
      };
    }

    const dialogueCategory = category === 'main_story' ? 'main_story' : 'side_story';
    merchantDialogues[frontmatter.merchantId][dialogueCategory].push(...dialogues.map(text => ({
      text: text,
      nodeId: frontmatter.nodeId,
      triggerCondition: {
        questId: frontmatter.questId,
        stage: frontmatter.stage,
        nodeId: frontmatter.nodeId
      }
    })));

    // Generate quest if this is a main story node
    if (category === 'main_story' && frontmatter.questName) {
      const quest = generateQuestTemplate(frontmatter, category);
      quests.push(quest);
    }

  } catch (error) {
    validationReport.errors.push(`Failed to process ${filePath}: ${error.message}`);
  }
}

/**
 * Parse markdown with frontmatter
 */
function parseMarkdown(content) {
  const frontmatterRegex = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/;
  const match = content.match(frontmatterRegex);

  if (!match) {
    return { frontmatter: {}, body: content };
  }

  const frontmatterText = match[1];
  const body = match[2];

  // Parse YAML-like frontmatter
  const frontmatter = {};
  const lines = frontmatterText.split('\n');

  for (const line of lines) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;

    const key = line.substring(0, colonIndex).trim();
    let value = line.substring(colonIndex + 1).trim();

    // Parse arrays
    if (value.startsWith('[') && value.endsWith(']')) {
      value = JSON.parse(value);
    }
    // Parse numbers
    else if (!isNaN(value)) {
      value = Number(value);
    }
    // Parse booleans
    else if (value === 'true') {
      value = true;
    } else if (value === 'false') {
      value = false;
    }
    // Remove quotes from strings
    else if ((value.startsWith('"') && value.endsWith('"')) ||
             (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }

    frontmatter[key] = value;
  }

  return { frontmatter, body };
}

/**
 * Extract dialogue lines from markdown body
 */
function extractDialogues(body) {
  const dialogues = [];

  // Extract dialogue lines (lines starting with "> ")
  const lines = body.split('\n');
  for (const line of lines) {
    if (line.trim().startsWith('> ')) {
      const dialogue = line.trim().substring(2).trim();
      if (dialogue.length > 0) {
        dialogues.push(dialogue);
      }
    }
  }

  return dialogues;
}

/**
 * Generate quest template from frontmatter
 */
function generateQuestTemplate(frontmatter, category) {
  return {
    id: frontmatter.questId || `quest_${frontmatter.nodeId}`,
    name: frontmatter.questName || `${frontmatter.merchantId}와의 대화`,
    description: frontmatter.questDescription || `${frontmatter.merchantId}를 찾아가 대화를 나누세요`,
    category: category,
    type: 'dialogue',
    level_requirement: frontmatter.levelRequirement || 1,
    required_license: frontmatter.requiredLicense || 0,
    prerequisites: frontmatter.prerequisites || [],
    objectives: [
      {
        type: 'dialogue',
        merchantId: frontmatter.merchantId,
        nodeId: frontmatter.nodeId,
        description: `${frontmatter.merchantId}와 대화하기`
      }
    ],
    rewards: frontmatter.rewards || {
      experience: 100,
      money: 1000,
      trustPoints: 10
    },
    auto_complete: true,
    repeatable: false,
    time_limit: null,
    is_active: true,
    sort_order: frontmatter.sortOrder || frontmatter.nodeOrder || 0
  };
}

/**
 * Validate all references
 */
async function validateReferences() {
  const merchantIds = Object.keys(merchantDialogues);
  const nodeIds = storyGraph.nodes.map(n => n.nodeId);
  const questIds = quests.map(q => q.id);

  // Validate next node references
  for (const node of storyGraph.nodes) {
    for (const nextNodeId of node.nextNodes) {
      if (!nodeIds.includes(nextNodeId)) {
        validationReport.errors.push(
          `Dangling reference: Node ${node.nodeId} references non-existent next node ${nextNodeId}`
        );
      }
    }
  }

  // Check for duplicate node IDs
  const duplicates = nodeIds.filter((id, index) => nodeIds.indexOf(id) !== index);
  if (duplicates.length > 0) {
    validationReport.errors.push(`Duplicate node IDs: ${duplicates.join(', ')}`);
  }

  // Statistics
  validationReport.stats = {
    totalNodes: storyGraph.nodes.length,
    totalMerchants: merchantIds.length,
    totalQuests: quests.length,
    mainStoryNodes: storyGraph.nodes.filter(n =>
      quests.some(q => q.id === n.questId && q.category === 'main_story')
    ).length,
    sideQuestNodes: storyGraph.nodes.filter(n =>
      quests.some(q => q.id === n.questId && q.category === 'side_quest')
    ).length
  };
}

/**
 * Write all output files
 */
async function writeOutputFiles(outputDir) {
  // Write story graph
  await writeFile(
    path.join(outputDir, 'storyGraph.json'),
    JSON.stringify(storyGraph, null, 2)
  );
  console.log('  ✓ storyGraph.json');

  // Write merchant dialogues
  for (const [merchantId, dialogues] of Object.entries(merchantDialogues)) {
    const dialoguesDir = path.join(outputDir, 'merchantDialogues');
    await writeFile(
      path.join(dialoguesDir, `${merchantId}.json`),
      JSON.stringify(dialogues, null, 2)
    );
    console.log(`  ✓ merchantDialogues/${merchantId}.json`);
  }

  // Write quests
  await writeFile(
    path.join(outputDir, 'quests.json'),
    JSON.stringify(quests, null, 2)
  );
  console.log('  ✓ quests.json');

  // Write validation report
  await writeFile(
    path.join(outputDir, 'validationReport.json'),
    JSON.stringify(validationReport, null, 2)
  );
  console.log('  ✓ validationReport.json');
}

/**
 * Print summary
 */
function printSummary() {
  console.log('\n📊 Export Summary:');
  console.log(`  Story Nodes: ${validationReport.stats.totalNodes}`);
  console.log(`  Main Story: ${validationReport.stats.mainStoryNodes} nodes`);
  console.log(`  Side Quests: ${validationReport.stats.sideQuestNodes} nodes`);
  console.log(`  Merchants: ${validationReport.stats.totalMerchants}`);
  console.log(`  Quests: ${validationReport.stats.totalQuests}`);

  if (validationReport.errors.length > 0) {
    console.log(`\n⚠️  Errors: ${validationReport.errors.length}`);
    validationReport.errors.forEach(err => console.log(`    - ${err}`));
  }

  if (validationReport.warnings.length > 0) {
    console.log(`\n⚠️  Warnings: ${validationReport.warnings.length}`);
    validationReport.warnings.forEach(warn => console.log(`    - ${warn}`));
  }
}

// Run export
if (require.main === module) {
  exportStoryAssets();
}

module.exports = { exportStoryAssets };
```

### 5.2 Markdown Format Template

**Example:** `way3/Story/MainStory/Phase1/Chapter1/scene1.md`

```markdown
---
nodeId: phase1_ch1_scene1
questId: quest_phase1_ch1_scene1
questName: "마리와의 첫 만남"
questDescription: "마포의 염력사 마리를 찾아가 인사를 나누세요"
merchantId: mari
stage: 1
nodeOrder: 1
nextNodes: ["phase1_ch1_scene2"]
chapterName: "Chapter 1: The Awakening"
sceneName: "Meeting Mari"
isKeyMoment: true
levelRequirement: 1
requiredLicense: 0
prerequisites: []
rewards: {"experience": 100, "money": 1000, "trustPoints": 10}
sortOrder: 1
---

# Scene 1: Meeting Mari

## Context
Player arrives at Mari's shop in Mapo district for the first time. The shop has a mystical atmosphere with floating crystals and soft ethereal light.

## Dialogues

> 처음 뵙겠습니다. 저는 염력사 마리입니다. 마포에서 특별한 물건들을 다루고 있죠.

> 당신의 에너지가 느껴지네요... 평범한 손님은 아니신 것 같습니다.

> 제 가게에선 마음의 힘으로 물건을 강화할 수 있어요. 관심 있으시다면 설명해 드릴게요.

## Narrative Notes
- First introduction to psychic enhancement system
- Establishes Mari's friendly but mysterious personality
- Sets up player's special nature

## Next Steps
Player receives quest to help Mari with a small task (scene 2)
```

### 5.3 Seed Script

**File:** `way-server/scripts/story/seed_story_data.js` (NEW)

```javascript
// 📁 scripts/story/seed_story_data.js - Seed story data into database
const fs = require('fs');
const path = require('path');
const DatabaseManager = require('../../src/database/DatabaseManager');
const logger = require('../../src/config/logger');
const { randomUUID } = require('crypto');

const VERSION = 'v1';
const STORY_DATA_DIR = path.join(__dirname, `../../src/database/merchant_data/story/${VERSION}`);

async function seedStoryData() {
  console.log('🌱 Starting story data seeding...\n');

  try {
    // Load exported data
    console.log('📥 Loading exported data...');
    const storyGraph = JSON.parse(fs.readFileSync(
      path.join(STORY_DATA_DIR, 'storyGraph.json'),
      'utf-8'
    ));

    const quests = JSON.parse(fs.readFileSync(
      path.join(STORY_DATA_DIR, 'quests.json'),
      'utf-8'
    ));

    const merchantDialoguesDir = path.join(STORY_DATA_DIR, 'merchantDialogues');
    const merchantFiles = fs.readdirSync(merchantDialoguesDir);

    // Seed story nodes
    console.log('\n🗺️  Seeding story nodes...');
    for (const node of storyGraph.nodes) {
      await DatabaseManager.run(`
        INSERT OR REPLACE INTO story_nodes (
          id, node_id, quest_id, merchant_id, stage, node_order,
          next_nodes, branch_condition, metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        node.id,
        node.nodeId,
        node.questId,
        node.merchantId,
        node.stage,
        node.nodeOrder,
        JSON.stringify(node.nextNodes),
        node.branchCondition ? JSON.stringify(node.branchCondition) : null,
        JSON.stringify(node.metadata)
      ]);
      console.log(`  ✓ ${node.nodeId}`);
    }

    // Seed quests
    console.log('\n📋 Seeding quest templates...');
    for (const quest of quests) {
      await DatabaseManager.run(`
        INSERT OR REPLACE INTO quest_templates (
          id, name, description, category, type, level_requirement,
          required_license, prerequisites, objectives, rewards,
          auto_complete, repeatable, time_limit, is_active, sort_order
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        quest.id,
        quest.name,
        quest.description,
        quest.category,
        quest.type,
        quest.level_requirement,
        quest.required_license,
        JSON.stringify(quest.prerequisites),
        JSON.stringify(quest.objectives),
        JSON.stringify(quest.rewards),
        quest.auto_complete ? 1 : 0,
        quest.repeatable ? 1 : 0,
        quest.time_limit,
        quest.is_active ? 1 : 0,
        quest.sort_order
      ]);
      console.log(`  ✓ ${quest.name}`);
    }

    // Seed merchant dialogues
    console.log('\n💬 Seeding merchant dialogues...');
    for (const file of merchantFiles) {
      const merchantId = path.basename(file, '.json');
      const dialogues = JSON.parse(fs.readFileSync(
        path.join(merchantDialoguesDir, file),
        'utf-8'
      ));

      // Process story dialogues (main_story and side_story categories)
      for (const category of ['main_story', 'side_story']) {
        if (!dialogues[category]) continue;

        for (let i = 0; i < dialogues[category].length; i++) {
          const dialogue = dialogues[category][i];

          await DatabaseManager.run(`
            INSERT INTO merchant_dialogues (
              id, merchant_id, trigger_type, trigger_condition,
              dialogue_text, dialogue_order, is_active
            ) VALUES (?, ?, ?, ?, ?, ?, 1)
          `, [
            randomUUID(),
            merchantId,
            category,
            JSON.stringify(dialogue.triggerCondition),
            dialogue.text,
            i
          ]);
        }
      }

      console.log(`  ✓ ${merchantId} (${dialogues.main_story?.length || 0} main, ${dialogues.side_story?.length || 0} side)`);
    }

    console.log('\n✅ Story data seeded successfully!');
    console.log(`\n📊 Summary:`);
    console.log(`  Story Nodes: ${storyGraph.nodes.length}`);
    console.log(`  Quests: ${quests.length}`);
    console.log(`  Merchants with dialogues: ${merchantFiles.length}`);

  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  }
}

// Run seeding
if (require.main === module) {
  seedStoryData()
    .then(() => process.exit(0))
    .catch(err => {
      console.error(err);
      process.exit(1);
    });
}

module.exports = { seedStoryData };
```

### 5.4 Package Scripts

**Add to `way-server/package.json`:**

```json
{
  "scripts": {
    "story:export": "node scripts/story/export_story_assets.js",
    "story:seed": "node scripts/story/seed_story_data.js",
    "story:full": "npm run story:export && npm run story:seed"
  }
}
```

---

## 6. Data Flow & User Experience

### 6.1 Session Start Flow

```
1. App Launch
   ↓
2. AuthManager.login()
   ↓
3. GameManager.initialize()
   ↓
4. Parallel Fetch:
   - fetchPlayer()
   - fetchQuests()
   - StoryManager.fetchStoryProgress()
   ↓
5. StoryManager.syncWithQuests(activeQuests)
   ↓
6. UI Ready with:
   - Available quests (including story quests)
   - Current story node
   - Story-relevant merchants highlighted
```

### 6.2 Merchant Interaction Flow

```
1. Player taps merchant on map
   ↓
2. MerchantDetailView appears
   ↓
3. MerchantDetailViewModel.loadMerchant(id)
   ├─ Fetch merchant detail
   ├─ Fetch inventory
   ├─ Fetch relationship
   └─ Check StoryManager.hasActiveStoryNode(merchantId)
       ├─ YES: Load story dialogue with quest context
       │        GET /merchants/:id/dialogues?questId=X&nodeId=Y
       │        ↓
       │        Display story dialogue with typing animation
       │        ↓
       │        Player reads and optionally chooses response
       │        ↓
       │        completeStoryDialogue(choiceId)
       │        ↓
       │        POST /game/quests/progress {
       │          eventType: "dialogue",
       │          eventData: { merchantId, nodeId, choiceId }
       │        }
       │        ↓
       │        Server updates:
       │        - player_quests progress
       │        - player_story_progress
       │        - Check quest completion
       │        - Unlock next nodes/quests
       │        ↓
       │        Client refreshes:
       │        - Quest list
       │        - Story progress
       │        ↓
       │        Show completion animation
       │        Display next available quest/node
       │
       └─ NO: Load regular greeting dialogue
              Continue with normal merchant interaction
```

### 6.3 Quest Completion Flow

```
1. Player completes dialogue with merchant
   ↓
2. POST /game/quests/progress { eventType: "dialogue", ... }
   ↓
3. Server handleDialogueProgress():
   ├─ Find active quests with dialogue objectives
   ├─ Match by merchantId + nodeId
   ├─ Update quest progress
   └─ Check if all objectives complete
       ├─ YES: Mark quest as completed
       │        ↓
       │        StoryService.advanceStoryNode(nodeId)
       │        ├─ Mark node as completed
       │        ├─ Determine next nodes
       │        └─ Update player_story_progress
       │        ↓
       │        Check for unlocked side quests
       │        ↓
       │        Return completion data
       │
       └─ NO: Return progress update
   ↓
4. Client receives response
   ↓
5. GameManager.refreshQuestsData()
   ├─ Fetch updated quest list
   └─ StoryManager.fetchStoryProgress()
   ↓
6. UI updates:
   ├─ Quest completed animation
   ├─ New quests available
   ├─ Story progress indicator
   └─ Next merchant highlighted (if applicable)
```

---

## 7. Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal:** Database schema and basic infrastructure

**Server:**
- [ ] Create `story_nodes` table migration
- [ ] Create `player_story_progress` table migration
- [ ] Add "dialogue" quest type to QuestService
- [ ] Update `merchant_dialogues` table to support trigger_condition

**Client:**
- [ ] Create `StoryModels.swift` with data structures
- [ ] Add `mainStory` and `sideStory` to DialogueCategory
- [ ] Extend NetworkManager with story endpoints

**Testing:**
- [ ] Database schema validation
- [ ] Basic model encoding/decoding tests

---

### Phase 2: Core Server API (Week 2)
**Goal:** Server-side story progression logic

**Server:**
- [ ] Implement `StoryService.js` with core methods:
  - `getPlayerStoryProgress()`
  - `advanceStoryNode()`
  - `checkNodePrerequisites()`
  - `getAvailableStoryNodes()`
- [ ] Enhance `GET /merchants/:id/dialogues` with quest context filtering
- [ ] Create `GET/POST /game/story/progress` routes
- [ ] Extend quest progress handler for dialogue events

**Testing:**
- [ ] Unit tests for StoryService methods
- [ ] API integration tests for dialogue filtering
- [ ] Quest progress tests with dialogue events

---

### Phase 3: Export Tooling (Week 3)
**Goal:** Story content pipeline

**Tooling:**
- [ ] Build `export_story_assets.js` script
- [ ] Build `seed_story_data.js` script
- [ ] Add npm scripts to package.json
- [ ] Create markdown template documentation

**Content:**
- [ ] Convert Phase 1 Chapter 1 to markdown format
- [ ] Run export script and validate output
- [ ] Seed test data to development database

**Testing:**
- [ ] Export validation (no errors)
- [ ] Seed success verification
- [ ] Manual testing with seeded data

---

### Phase 4: Client Integration (Week 4)
**Goal:** Client-side story system

**Client:**
- [ ] Implement `StoryManager.swift`
- [ ] Integrate StoryManager with GameManager
- [ ] Enhance `MerchantDetailViewModel` with story dialogue support
- [ ] Enhance `DialogueDataManager` for quest-aware fetching

**Testing:**
- [ ] StoryManager unit tests
- [ ] Dialogue fetching with quest context
- [ ] Story progress synchronization

---

### Phase 5: UI & Polish (Week 5)
**Goal:** User-facing features and UX

**UI:**
- [ ] Story dialogue display in MerchantDetailView
- [ ] Choice buttons for branching dialogues
- [ ] Quest progress visualization for story quests
- [ ] Map markers for story-relevant merchants
- [ ] Completion animations

**Polish:**
- [ ] Typing animation for story dialogues
- [ ] Smooth transitions between nodes
- [ ] Error handling and fallbacks
- [ ] Loading states

**Testing:**
- [ ] End-to-end story flow
- [ ] UI interaction testing
- [ ] Offline behavior validation

---

### Phase 6: QA & Rollout (Week 6)
**Goal:** Production readiness

**QA:**
- [ ] Full story progression testing
- [ ] Multi-device sync verification
- [ ] Offline/online mode transitions
- [ ] Performance profiling
- [ ] Edge case testing

**Documentation:**
- [ ] Admin guide for story management
- [ ] Content creator guide for markdown format
- [ ] API documentation updates
- [ ] Player-facing help text

**Rollout:**
- [ ] Staging deployment
- [ ] Phased rollout strategy
- [ ] Monitoring setup
- [ ] Rollback plan

---

## 8. Risk Assessment

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Story state desync between client/server | High | Medium | Server is source of truth, client validates before submission |
| Complex branching causes state issues | Medium | Medium | Start with linear progression, add branching incrementally |
| Performance with large story graph | Medium | Low | Paginate story nodes, load only active chapters |
| Backward compatibility breaks | High | Low | Additive changes only, no breaking modifications |

### Content Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Incomplete merchant dialogues | Medium | Medium | Validation script + fallback dialogues |
| Story script revisions require migration | Medium | High | Version story exports, maintain migration scripts |
| Content/code deployment mismatch | Low | Medium | Feature flags for story activation |

### Operational Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Player progress loss | High | Low | Regular backups + audit logs |
| Story content not ready | Medium | Medium | Decouple code from content release |
| High support burden | Low | Medium | Clear error messages + help documentation |

---

## 9. Success Metrics

### Technical Metrics
- ✅ Story system deployed without breaking existing features
- ✅ < 2s average story dialogue load time
- ✅ > 95% dialogue fetch success rate
- ✅ Zero story state desync issues in production

### User Experience Metrics
- ✅ > 70% of active players engage with story quests
- ✅ > 60% story quest completion rate
- ✅ < 5% story-related support tickets
- ✅ > 4.0 star rating for story content

### Content Metrics
- ✅ Phase 1 (3 chapters) deployed within 6 weeks
- ✅ 2 side quests per major merchant
- ✅ < 2 days from story markdown to deployment

---

## 10. Next Steps

### Immediate Actions
1. **Review this design document** with team for feedback
2. **Create GitHub issues** for each implementation phase
3. **Set up Story directory structure** in repository
4. **Run database migrations** for new tables
5. **Create first story markdown** as template

### Development Kickoff
1. **Week 1 Sprint Planning**: Assign Phase 1 tasks
2. **Set up development environment**: Story directories, tooling
3. **Begin parallel work**: Server (database) + Client (models)

### Long-term Planning
1. **Phase 2+ story content**: Plan narrative arc beyond Phase 1
2. **Localization pipeline**: Prepare for multi-language support
3. **Analytics instrumentation**: Track story engagement metrics
4. **LiveOps strategy**: Plan for seasonal story events

---

## Appendix: File Structure Reference

```
way-server/
├── src/
│   ├── services/
│   │   ├── admin/
│   │   │   └── QuestService.js (ENHANCED)
│   │   └── game/
│   │       ├── QuestPlayerService.js (ENHANCED)
│   │       └── StoryService.js (NEW)
│   ├── routes/
│   │   ├── api/
│   │   │   └── merchants.js (ENHANCED)
│   │   └── game/
│   │       ├── quests.js (ENHANCED)
│   │       └── story.js (NEW)
│   └── database/
│       └── merchant_data/
│           └── story/
│               └── v1/
│                   ├── storyGraph.json
│                   ├── quests.json
│                   ├── validationReport.json
│                   └── merchantDialogues/
│                       ├── mari.json
│                       └── ...
├── scripts/
│   └── story/
│       ├── export_story_assets.js (NEW)
│       └── seed_story_data.js (NEW)
└── Story/
    ├── MainStory/
    │   ├── Phase1/
    │   │   ├── Chapter1/
    │   │   │   ├── scene1.md
    │   │   │   └── scene2.md
    │   │   └── Chapter2/
    │   └── Phase2/
    └── MerchantSideQuests/
        ├── mari_side1.md
        └── mari_side2.md

way3/
├── way3/
│   ├── Models/
│   │   └── StoryModels.swift (NEW)
│   ├── Managers/
│   │   ├── GameManager.swift (ENHANCED)
│   │   └── StoryManager.swift (NEW)
│   ├── Core/
│   │   └── DialogueDataManager.swift (ENHANCED)
│   ├── ViewModels/
│   │   └── MerchantDetailViewModel.swift (ENHANCED)
│   └── Views/
│       ├── Merchant/
│       │   └── MerchantDetailView.swift (ENHANCED)
│       └── Quest/
│           └── QuestView.swift (ENHANCED)
└── claudedocs/
    └── story-system-design.md (THIS FILE)
```

---

**Document Version:** 1.0
**Last Updated:** 2025-10-01
**Author:** Claude (System Design Specialist)
**Status:** Ready for Implementation