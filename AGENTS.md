# Repository Guidelines

## Project Structure & Module Organization
- `way3/` contains the SwiftUI iOS client; UI views sit in `Views/`, models in `Models/`, logic helpers in `Managers/`, and assets inside `Resources/` and `Assets.xcassets`.
- `way3Tests/` and `way3UITests/` host XCTest targets mirrored to app modules for unit/UI coverage.
- `theway_server/` holds the Node.js backend (`src/app.js`, `src/routes/`, `src/services/`, `src/socket/`, `src/database/` for migrations/seeds, `public/` for static assets) plus runtime state under `data/` and `logs/`.
- Repository utilities live in `claudedocs/`, while `start_server.sh` boots the backend from the repo root.

## Build, Test, and Development Commands
- Open the client with `open way3.xcodeproj` (or `xed .`); CLI builds run via `xcodebuild -scheme way3 -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- From `theway_server/`, run `npm install` to sync dependencies and `npm run dev` (or `../start_server.sh`) for a hot-reload backend.
- Execute `npm run migrate` to apply schema changes; set `RUN_SEED=true npm run seed` for reference data.
- Use `npm start` for a production-style launch.

## Coding Style & Naming Conventions
- Swift code uses 4-space indentation, `UpperCamelCase` types, `lowerCamelCase` members, and `// MARK:` sectioning; order SwiftUI modifiers from layout to appearance.
- JavaScript follows CommonJS modules, 4-space indentation, single quotes, and centralized logging through `config/logger`.
- Name assets with lowercase-hyphen patterns (e.g. `merchant-avatar.png`) and align new folders with the existing domain taxonomy (Managers, ViewModels, etc.).

## Testing Guidelines
- Place Swift unit tests beside their modules (e.g. `way3Tests/Core`), naming classes `<TypeName>Tests` and functions `test_<scenario>_...`.
- Run `xcodebuild test -scheme way3 -destination 'platform=iOS Simulator,name=iPhone 15'` before opening a PR.
- Backend tests use Jest; add specs under `theway_server/src/**/__tests__` and execute `npm test`. Prioritize controllers/services touching persistence or sockets.

## Commit & Pull Request Guidelines
- Prefer conventional messages (`feat: add merchant quest sync`) over generic “update”; group changes by feature or fix and note schema shifts in the body.
- Confirm relevant builds/tests are green, summarize client/server impact, and link issues in every PR. Attach simulator screenshots for visible changes.
- Update `.env.example` whenever new configuration keys are introduced and call that out in the PR description.

## Environment & Security Notes
- Copy `.env.example` into `theway_server/.env`; never commit secrets, SQLite dumps, or populated `logs/`.
- Ensure `ALLOWED_ORIGINS` reflects local device IPs during multi-device tests, and reset it before release.
- Use `start_server.sh` for consistent setup: it validates Node versions, directories, and checks for `.env`.
