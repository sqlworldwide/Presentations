# 014 - VS Code: Plan mode, then Schema Designer with Copilot

```
014_VSCode_PlanMode_SchemaDesigner.md
Demo 1, step 9 - VS Code: Plan mode, then Schema Designer with Copilot (about 4 min)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 10, 2026
```

**Needs:** `005_Pre_VSCode_BlankDatabase.sql` (empty `LibraryDemo`) and the `DemoFiles\VSCodeWorkspace` folder open in VS Code (013).

**Learn facts**
- Plan mode is a VS Code chat mode (not MSSQL-specific). Copilot evaluates a request without
  changing anything; then you switch to agent mode or Schema Designer to carry out the plan.
- MSSQL extension features table: *Schema designer with GitHub Copilot* is GA – natural-language
  schema design with visual change tracking.
- In rehearsal Copilot applied every change directly. There is no review step to show.

## On stage
1. **Connect** to `taiob2\MSSQLSERVER01` > `LibraryDemo` in the MSSQL Connections view.
2. **Plan mode.** In Copilot Chat, stay in Agent mode and paste the whole prompt, starting with `/plan`
   (no mode dropdown needed):
   ```
   /plan Plan the database schema for a small library: Books, Authors (a book can have several authors), Members, and BookLoans with due dates and return dates. Treat each Book as one lendable item. Follow the repo's T-SQL conventions. Keep the plan to one page: tables, keys and foreign keys, plus at most two constraints. Save the plan as plan.md in the root of the VSCodeWorkspace folder.
   ```

   Rehearsal 10 Nov (Copilot Fusion picked GPT-6.1 Sol): 10 steps, 1 min 14 s, `plan.md` written
   to the workspace root. Plan asked 2 clarifying questions first. Answer them quickly:
   - *VSCodeWorkspace folder:* pick `DemoFiles\VSCodeWorkspace` (the list also offered `mcpDemo`).
   - *Loan rules and constraint scope:* date-only loan, due and return values; a NULL return date
     means the loan is active; the two extra constraints are date order and one active loan per book.

   Keep this script open in a second VS Code window, not in the demo window, and open it after the
   demo to show the steps. In rehearsal Copilot read this file first because its tab was attached to
   the chat. The wording and the questions will differ on every run.

   Point out: it plans, it doesn't touch the database.

   **If Plan mode fails or the file doesn't land in the folder:** copy
   `DemoFiles\014_VSCode_PlanMode_SchemaDesigner_Plan.md` to `DemoFiles\VSCodeWorkspace\plan.md`
   and go on to step 3. That file is a saved plan from an earlier run of this same prompt.
3. **Build it in Schema Designer.** Right-click `LibraryDemo` > **Visualize and Design Schema…**.
   When the canvas opens, select **Chat** (the Copilot icon) in the toolbar. Prompt (Learn's pattern):
   ```
   Based on #file:plan.md, use Schema Designer to create all the tables and relationships in my database. Focus on the database schema only – skip any application layer items from the plan.
   ```

   If the Chat button isn't there: right-click `LibraryDemo` > **Open in GitHub Copilot Agent** and
   send the same prompt. Learn: Agent mode opens Schema Designer and creates each table.

   Copilot applies the changes directly. Show the finished tables and relationships on the canvas.
   In rehearsal Schema Designer could not set the `PK_<TableName>` key names from the plan. Point at
   the identity keys, not the key names.

4. **Add the constraints (about 30 seconds).** In the main Copilot Chat, Agent mode:
   ```
   Add a unique constraint on BookAuthor (BookID, AuthorID) and a check that the due date is on or after the loan date.
   ```
   Copilot runs T-SQL on the `LibraryDemo` connection and applies it directly (rehearsal 11 Nov: 7
   steps, 30 s, three queries). It reports `UQ_BookAuthor_BookID_AuthorID` and
   `CK_BookLoan_DueDate`, and says the check is enabled and trusted. This is not a Schema Designer
   change, so there is no diff. Say: *"Schema Designer built the structure. The constraints went in
   as T-SQL from Agent mode."* The filtered unique index and the supporting indexes stay in the plan
   text. Do not ask for them live.
5. Line to land: *"The plan is the spec. Copilot builds from it, and I check what it built."*

## If time is short
Skip step 2: copy the saved plan (`014_VSCode_PlanMode_SchemaDesigner_Plan.md`) to
`VSCodeWorkspace\plan.md` and go straight to step 3.

## Reset
- Run `005_Pre_VSCode_BlankDatabase.sql` again (it drops and recreates `LibraryDemo`).
- Delete `DemoFiles\VSCodeWorkspace\plan.md`. Leave the `.github` folder alone.
