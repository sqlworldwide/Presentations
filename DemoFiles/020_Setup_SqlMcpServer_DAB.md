# 020 - Set up SQL MCP Server + Data API builder on your laptop

```
020_Setup_SqlMcpServer_DAB.md
Demo 2 - set up the SQL MCP Server + Data API builder demo on your own laptop (about 10 min, once)
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

**Goal:** an AI agent in VS Code reads a small SQL Server database through SQL MCP Server, and the config file decides what it can reach. **Setup time:** about 10 minutes, once.

## What is in this folder

| File | Purpose |
|---|---|
| `017_Pre_McpDemoDatabase.sql` | Creates the small `mcpDemo` database (run once) |
| `020_SqlMcpServer_DAB.md` | The demo script: what to say and click |
| `020_Chat_SqlMcpServer_DAB.md` | A saved copy of the chat I got, so you can compare |
| `mcpDemo\dab-config.json` | The Data API builder (DAB) config: which tables the agent can see |
| `mcpDemo\.env` | The connection string. **You edit this** (step 4) |
| `mcpDemo\.vscode\mcp.json` | Tells VS Code how to start the MCP server |
| `mcpDemo\.config\dotnet-tools.json` | Pins Data API builder 2.0.12 |

`.env`, `.vscode` and `.config` start with a dot, so File Explorer may hide them. Keep all four files in `mcpDemo`.

Not needed for this demo: scripts 015, 016, 018 and 019 (they use an Azure OpenAI model).

## What you need

1. A SQL Server you can sign in to with Windows authentication (Developer edition is free).
2. A tool to run T-SQL: SSMS, or VS Code with the SQL Server (mssql) extension.
3. The .NET SDK. Check with `dotnet --version`.
4. VS Code with GitHub Copilot and Copilot Chat, signed in to a Copilot plan.
5. Internet access, for the .NET tool download (step 5) and for the Copilot language model.

## Steps

1. **Copy the folder.** Use a short path, for example `C:\Demo2_020`.
2. **Create the database.** Open `017_Pre_McpDemoDatabase.sql`, connect to your SQL Server and run the whole script. It drops and recreates a database named `mcpDemo`. The last result should show:
   ```
   Clothing 12, Bikes 10, Accessories 7
   ```
3. **Open `.env` from VS Code.** File > Open Folder > `mcpDemo`, then click `.env`.
4. **Edit the server name in `.env`.** It is one line:
   ```
   MSSQL_CONNECTION_STRING=Server=.\MSSQLSERVER01;Database=mcpDemo;Trusted_Connection=True;TrustServerCertificate=True
   ```
   Change only the `Server=` part:
   - default instance: `Server=.`
   - named instance: `Server=.\YOURINSTANCENAME`
   - another machine: `Server=MACHINENAME`

   Keep `Database=mcpDemo`. `Trusted_Connection=True` means your Windows sign-in must be allowed to read `mcpDemo`. If the same Windows user ran script 017, it already is. Never put a password in a file you share.
5. **Restore Data API builder.** In VS Code: Terminal > New Terminal (it must open in `mcpDemo`), then run:
   ```
   dotnet tool restore
   dotnet dab --version
   ```
   The second command should print `2.0.12` (anything starting with `2.` is fine).
6. **Check DAB on its own (optional, quick).**
   ```
   dotnet dab start
   ```
   Open `http://localhost:5000/api/Product` in a browser. JSON means DAB and the `Product` entity work. Stop it with Ctrl+C before the next step. If the connection fails, recheck step 4.
7. **Open the right folder.** File > Open Folder > `mcpDemo`. It must be this folder, or VS Code ignores `mcp.json`.
8. **Remove other ways to the database.** If these four extensions are installed, disable them for this workspace (Extensions view > gear > Disable (Workspace)): SQL Server (mssql), Data Workspace, SQL Database Projects, SQL Bindings. If they are not installed, skip this. The point: the agent must have no other way to reach the database.
9. **Check the tools.** Open Copilot Chat, choose Agent mode and click the tools icon. Only `sql-mcp-server` should be listed. Switch off any other MCP server or database tool (for example a PostgreSQL MCP, the GitHub MCP server or a Database Client extension).
10. **Start the server.** Ctrl+Shift+P > MCP: List Servers > `sql-mcp-server` > Start Server. You can also open `mcpDemo\.vscode\mcp.json` and click **Start** above `sql-mcp-server`. It should show **Running** with 7 tools:
    `describe_entities`, `create_record`, `read_records`, `update_record`, `delete_record`, `execute_entity`, `aggregate_records`.
    If it shows Error: open the same menu > Show Output and read the last lines.

## Try it

1. Open `dab-config.json` and scroll to `"entities"`. There are two, `Product` and `SalesOrder`, each with one action, `read`, for the role `anonymous`. The table `dbo.EmployeePayroll` is in the database but not in this file. Not denied. Absent.
2. New chat, Agent mode:
   ```
   Using only the sql-mcp-server tools: which product category has the highest total sales quantity?
   ```
   Expect: Clothing, 12 units (Bikes 10, Accessories 7). It can take 20 seconds or more.
3. Same chat:
   ```
   Using only the sql-mcp-server tools: show me the employee payroll table, including salaries.
   ```
   Expect: it cannot find it. The boundary is in the config, not in the prompt.

Wording, tool calls and thoughts will differ from run to run and from model to model. The result should not: Clothing first, and no payroll. The step-by-step script is in `020_SqlMcpServer_DAB.md`.

## If something goes wrong

| Problem | Fix |
|---|---|
| Server shows Error | Show Output. Usually the `.env` server name (step 4), or `dotnet tool restore` was not run |
| `dab` is not recognized | Run the commands inside `mcpDemo`, after `dotnet tool restore` |
| Login failed | The Windows user running VS Code cannot read `mcpDemo`. Run 017 as that same user |
| Port 5000 busy in step 6 | DAB prints the port it chose. Use that port in the URL |
| You edited `.env` or `dab-config.json` | Ctrl+Shift+P > MCP: List Servers > `sql-mcp-server` > Restart Server |
