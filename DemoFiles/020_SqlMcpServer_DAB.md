# 020 - SQL MCP Server + Data API builder

```
020_SqlMcpServer_DAB.md
Demo 2 - SQL MCP Server + Data API builder: an agent reads, and the config decides what it can reach (about 4 min)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 10, 2026

Needs 017.
```

**Demo:** the configuration controls what the agent can access. **Run time:** about 4 minutes.

## Before you start
- Complete the setup in [020_Setup_SqlMcpServer_DAB.md](020_Setup_SqlMcpServer_DAB.md).
  - It covers the SQL Server prerequisite, database setup, `.env`, DAB tool restore, and starting `sql-mcp-server`.
- Open the `mcpDemo` folder in VS Code and confirm `sql-mcp-server` is running with its tools available.
- Open `mcpDemo\.vscode\mcp.json` and show **Running** above `sql-mcp-server` (the line reads `Running | Stop | More...`).
- Keep this as a local demo. The sample uses the `anonymous` role and is not a production security configuration.

## Demo
- Open [dab-config.json](mcpDemo/dab-config.json) and show `entities`.
  - Only `Product` and `SalesOrder` are exposed.
  - Both allow `read` for the `anonymous` role; neither allows writes.
  - `dbo.EmployeePayroll` exists in the database but is absent from this configuration.
  - Say: *"Not denied. Absent."*
- In Copilot Chat, select Agent mode and confirm the `sql-mcp-server` tools are available.
- Ask:
  - `Using only the sql-mcp-server tools: which product category has the highest total sales quantity?`
  - Expect: **Clothing, 12 units**; Bikes 10, Accessories 7.
  - In the tool trace (saved in `020_Chat_SqlMcpServer_DAB.md`), Copilot called `describe_entities`, `aggregate_records` and `read_records` twice. DAB ran the tool calls; the model mapped products to categories and added the totals.
  - The Nov 4 rehearsal took 23 seconds. Allow 20 seconds or more; duration and tool-call sequence can vary.
- In the same chat, ask:
  - `Using only the sql-mcp-server tools: show me the employee payroll table, including salaries.`
  - Expect: the agent says payroll is unavailable. The observed run called `describe_entities` and found only `Product` and `SalesOrder`.
  - Close with: *"The boundary is in the config, not in the prompt."* Keep this example; it demonstrates the access boundary.

## REST check
- Use this only to check DAB's REST API, not the agent's MCP tool call.
- Stop `sql-mcp-server` first: `Ctrl+Shift+P` > `MCP: List Servers` > `sql-mcp-server` > `Stop Server`.
- Open a **pwsh** terminal in `mcpDemo` (Windows PowerShell also works).
- Check whether port 5000 is already in use:
  ```powershell
  Get-NetTCPConnection -LocalPort 5000 -State Listen
  ```
  - If rows appear, the port is occupied. Stop the other DAB/MCP server before continuing.
  - If the command reports no matching objects, no listener was found. Continue with the next step.
- If VS Code shows **Start** but port 5000 is still occupied, check the process using the number in the **OwningProcess** column:
  ```powershell
  Get-CimInstance Win32_Process -Filter "ProcessId = <PID>" |
    Select-Object ProcessId, Name, CommandLine
  ```
  - Replace `<PID>` with the **OwningProcess** number from the port check, in both commands. This is a Windows process ID, not a SQL Server SPID, and it changes each time.
  - Only if the command line identifies the DAB/MCP process for this demo, stop it:
    ```powershell
    Stop-Process -Id <PID>
    ```
  - If it is an unfamiliar process, do not stop it.
- Start DAB:
  ```powershell
  dotnet dab start
  ```
- Open either URL in a browser:
  - Products: `http://localhost:5000/api/Product`
  - Sales orders: `http://localhost:5000/api/SalesOrder`
- JSON means that REST endpoint returned data. Each URL reads only its named entity.
- Show a filtered request in the browser (this local demo uses HTTP, not HTTPS):
  ```text
  http://localhost:5000/api/Product?$filter=Category%20eq%20%27Clothing%27
  ```
  - This encodes `$filter=Category eq 'Clothing'`, similar to SQL `WHERE Category = 'Clothing'`.
  - Expect only **Rain Shell**, the Clothing product in the sample data.
  - DAB applies the filter in the database query; the application does not need to download the whole table and filter it locally.
- Stop DAB with `Ctrl+C`, then restart `sql-mcp-server` from `MCP: List Servers` before continuing with MCP.
- If startup still reports `address already in use`, a DAB/MCP process may remain even when VS Code shows **Start**. Do not reuse a process ID from an earlier session; check the current one first.
- For connection or installation errors, follow [020_Setup_SqlMcpServer_DAB.md](020_Setup_SqlMcpServer_DAB.md).

## Learn more
- [SQL MCP Server overview](https://learn.microsoft.com/azure/data-api-builder/mcp/overview): tools, transports, permissions, and configuration.
- [VS Code MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers): configure, start, and troubleshoot servers.
