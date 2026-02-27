# TestSprite Tests – Mada App

This folder holds [TestSprite](https://www.testsprite.com/) configuration, PRD, and (after generation) test code and reports. TestSprite is an AI-powered testing agent that generates and runs UI/API tests.

## Prerequisites

1. **TestSprite MCP Server** installed and configured in your IDE (Cursor, VS Code, etc.).  
   See: [TestSprite Installation](https://docs.testsprite.com/mcp/getting-started/installation).

2. **Flutter web app running** so TestSprite can drive the UI in a browser:
   ```bash
   cd apps/mobile
   flutter run -d chrome
   ```
   Or run a web server on a fixed port (e.g. 8080):
   ```bash
   flutter run -d web-server --web-port=8080
   ```
   Note the URL (e.g. `http://localhost:8080`) and port for bootstrap.

3. **Test credentials** (optional but recommended for full flows): create a test user and, if needed, an active subscription or voucher code for subscription tests.

## Quick Start

In your IDE, ask the AI assistant (with TestSprite MCP enabled):

```text
Help me test this project with TestSprite.
```

The assistant will use the TestSprite MCP tools to:

1. **Bootstrap** – Detect project, port, and open configuration (use the PRD in this folder if prompted).
2. **Analyze** – Generate code summary and standardized PRD.
3. **Plan** – Create frontend (and optionally backend) test plans.
4. **Generate & execute** – Produce test code (e.g. Playwright) and run it.
5. **Report** – Output results and fix recommendations under `testsprite_tests/tmp/` and report files in this folder.

## Bootstrap Configuration (Reference)

When configuring TestSprite (via MCP or portal), you can use:

| Parameter     | Suggested value |
|---------------|-----------------|
| **projectPath** | Absolute path to workspace, e.g. `/Users/mohammedthamer/Desktop/mada_app` |
| **type**      | `frontend` |
| **localPort** | Port where Flutter web is running (e.g. `8080` or the port shown by `flutter run -d web-server --web-port=8080`) |
| **testScope** | `codebase` (full project) or `diff` (recent changes only) |
| **needLogin** | `true` if you want tests to cover post-login flows (Home, Courses, Books, Jobs, Subscription) |

Example (for MCP tool call):

```json
{
  "projectType": "frontend",
  "localPort": 8080,
  "testScope": "codebase",
  "needLogin": true,
  "credentials": {
    "username": "test@example.com",
    "password": "your-test-password"
  }
}
```

Use a **test account** with known credentials; optionally activate subscription (or use a test voucher) to cover gated content.

## PRD and Scope

- **PRD**: See [PRD.md](./PRD.md) for product overview, features, user flows, and validation criteria. Upload or point TestSprite to this file when asked for a PRD.
- **App**: Flutter app lives in `apps/mobile`; main entry is `lib/main.dart`; routes are in `lib/app/router.dart`.
- **RTL**: The app is RTL (Arabic). Generated selectors may need to account for RTL layout and Arabic text.

## Generated Artifacts

After a TestSprite run you typically get:

- `testsprite_tests/tmp/config.json` – Project configuration.
- `testsprite_tests/tmp/code_summary.json` – Code analysis.
- `testsprite_tests/tmp/test_results.json` – Execution results.
- `testsprite_tests/tmp/report_prompt.json` – AI-readable report and fix suggestions.
- `testsprite_tests/standard_prd.json` – Normalized PRD (if generated).
- `testsprite_tests/TC*.py` (or similar) – Generated test files (e.g. Playwright).
- `testsprite_tests/TestSprite_MCP_Test_Report.md` / `.html` – Human-readable reports.

## Rerun or Modify Tests

- **Rerun existing tests**: Ask the assistant to rerun TestSprite tests for this project (uses `testsprite_rerun_tests` with the same `projectPath`). Ensure the Flutter web app is running on the same port.
- **Modify tests**: Use TestSprite’s “modify or update tests” flow or open the test result dashboard from the MCP to edit and re-run specific cases.

## Flutter Unit/Widget Tests (Separate)

This repo also has **Flutter** tests (e.g. `apps/mobile/test/`) run with:

```bash
melos test
# or
cd apps/mobile && flutter test
```

Those are standard Flutter widget/unit tests, not TestSprite-generated Playwright tests. Use TestSprite for E2E/UI in the browser; use `flutter test` for in-process Flutter tests.
