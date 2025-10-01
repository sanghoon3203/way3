# Main Quest & Merchant Dialogue Master Plan

## 1. Shared Vision
- **Objective**: Deliver a cohesive main story that players experience entirely through merchant dialogues, while unlocking two narrative-driven side quests per merchant.
- **Approach**: Reuse the existing quest, dialogue, and progress infrastructure across server and Way3 app. Introduce only the scripts, data, and API extensions necessary to encode story structure and stage-aware merchant conversations.

## 2. Source Asset Pipeline
1. **Markdown Audit & Naming**
   - Keep story drafts under `Story/MainStory/<phase>/<chapter>/<scene>.md`.
   - Normalize IDs: `phaseX_chY_sceneZ` for main nodes, `merchantId_sideA` for merchant quests.
2. **Conversion Script** (`scripts/story/export_story_assets.js`)
   - Traverse Markdown hierarchy → emit
     - `storyGraph.json`: ordered nodes with metadata (nodeId, merchantId, objectives, nextNodes).
     - `merchantDialogues/<merchantId>.json`: buckets per `trigger_type` (greeting, special_event, etc.).
     - `validationReport.json`: missing merchants, dangling references, duplicate IDs.
   - Reuse patterns from `scripts/update_merchant_json.js` (fs/path helpers, JSON formatting).
   - Version outputs under `src/database/merchant_data/story/<version>/`.
3. **CI Hook (optional)**
   - Add npm script `story:export` for repeatable generation.
   - Future work: lint Markdown headings to ensure required front-matter (merchantId, stage, choices).

## 3. Database Modeling
1. **Quest Templates**
   - Main story:
     - `category = 'main_story'`, `type = 'story'`, sequential `sort_order`.
     - Each node objective: `{ "type": "dialogue", "merchantId": "mari", "nodeId": "phase1_ch1_scene2" }`.
     - Set `auto_complete = true` when single dialogue should finish the step.
   - Merchant side quests:
     - `category = 'side_quest'`, `prerequisites = [<main_story_id>]`.
     - Two quests per merchant, align objectives with dialogue nodes (`merchantId`, `nodeId`, optional item requirements).
2. **Insertion Path**
   - Use `QuestService.createQuestTemplate`/`updateQuestTemplate` to preserve validation + audit logs.
   - Seed data lives beside story exports in `src/database/merchant_data/story/quests.json` for reproducible provisioning.
3. **Player State**
   - Continue using `player_quests` for progress tracking; no new tables required.
   - Optional: add `player_story_state` view if analytics needs consolidated reporting.

## 4. Dialogue Seeding & Retrieval
1. **Seeding**
   - Import `merchantDialogues/*.json` into `merchant_dialogues` table.
   - `trigger_type` values: `greeting`, `shop`, `special_event`, `main_story`, `side_story`.
   - `trigger_condition` schema:
     ```json
     { "questId": "<uuid>", "stage": 2, "nodeId": "phase1_ch1_scene2" }
     ```
   - Preserve localization keys to support future translation.
2. **API Enhancements**
   - `GET /api/merchants/:merchantId/dialogues`
     - Accept `questId`, `stage`, `nodeId` query params alongside existing `triggerType`.
     - Filter by parsed `trigger_condition`; fallback to generic bucket when no match.
     - Response includes `nodeMetadata` (nodeId, questId, stage, prerequisites).
   - Maintain existing logging to `merchant_dialogue_logs` with quest metadata for analytics.

## 5. Quest Progression Logic
1. **Progress Handler**
   - Extend dialogue branch to validate `eventData.merchantId`, `eventData.nodeId`, or `eventData.dialogueId` against objective JSON.
   - Increment objective and auto-complete quest when all dialogue objectives met.
2. **Client Reporting**
   - Way3 app invokes `/game/quests/progress` (proxy to shared handler) with payload:
     ```json
     {
       "questId": "<uuid>",
       "eventType": "dialogue",
       "eventData": {
         "merchantId": "mari",
         "nodeId": "phase1_ch1_scene2",
         "choiceId": "A" // optional
       }
     }
     ```
   - Cache latest `nodeMetadata` locally via `DialogueDataManager` for optimistic UI updates.
3. **Auto Accept/Unlock**
   - When main quest stage unlocks merchant side quest, server calls `QuestService.acceptQuest` for eligible players.
   - Document unlocking rules to avoid cyclic prerequisites.

## 6. Client Integration
1. **Network Layer**
   - Continue using existing `/game/quests` for overview; add helper `NetworkManager.fetchMerchantDialogue(merchantId, triggerType, questId, stage)`.
   - Introduce `StoryManager` (or extend `GameManager`) to track active node, local cache, pending progress submissions.
2. **UI Flow**
   - Merchant interaction flow:
     1. Player taps merchant.
     2. App calls dialogue API with quest context.
     3. `MerchantDetailViewModel` renders lines via typing animation.
     4. On completion/choice → call `updateQuestProgress` with dialogue payload.
     5. Refresh quest overview; if new stage, request next dialogue.
   - Story-specific view (optional) to present cinematic sequences or branching choices beyond merchant UI.
3. **Fallback Strategy**
   - When offline or API fails, use bundled dialogue payload from story export to keep narrative flowing; sync progress once back online.

## 7. Tooling & QA
1. **Automation**
   - Integration tests:
     - Create mock player → accept first main quest → fetch merchant dialogue with stage → submit dialogue progress → assert quest completion.
   - Lint story exports for missing merchants, invalid next nodes.
2. **Admin Console**
   - Add filters for `category = 'main_story'` and stage search.
   - Provide preview of dialogue bundles tied to quests for CS/QA.
3. **Analytics**
   - Instrument `MetricsCollector.recordQuestEvent` when dialogue objectives complete.
   - Dashboard: completion funnel per stage, drop-off by merchant.

## 8. Rollout Checklist
- [ ] Run `story:export` and verify validation report is clean.
- [ ] Seed quest templates + merchant dialogues in staging via admin scripts.
- [ ] Execute integration tests and regression suite.
- [ ] QA story flow end-to-end on Way3 app (online/offline cases).
- [ ] Monitor `merchant_dialogue_logs` and analytics post-launch; hotfix script ready for data corrections.
- [ ] Document workflow for narrative editors and operations.

## 9. Future Enhancements
- Branching node conditions (player choices, inventory requirements).
- Localization pipeline using the same export artifacts.
- LiveOps hooks to schedule limited-time merchant stories using `trigger_condition` windows.
- Automated diffing of story exports to highlight narrative changes for reviewers.

## 10. Ownership & Communication
- **Narrative**: Maintains Markdown drafts, reviews validation report, signs off on storyGraph.
- **Backend**: Owns export script, database seeding, API filtering, progress handler updates.
- **Client**: Integrates StoryManager, dialogue fetching, and UI flow adjustments.
- **QA**: Develops integration scripts, monitors logs, manages regression cases.
- **PM/LiveOps**: Tracks rollout checklist, coordinates analytics review, approves hotfixes.