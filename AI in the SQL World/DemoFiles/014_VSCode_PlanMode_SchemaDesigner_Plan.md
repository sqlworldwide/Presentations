# Small library schema plan

Plan only: no database changes. Each `dbo.Book` row represents one lendable item;
no copy table or application layer.

## Conventions

Use schema-qualified singular PascalCase names and `nvarchar` for human-entered text.
Every table has an `int IDENTITY(1,1)` primary key named `<TableName>ID`, plus
`CreatedAt datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME()` and `ModifiedAt datetime2(0) NULL`.
Below, columns are `NOT NULL` unless marked `NULL`; common audit columns are omitted.

## Tables, keys, and foreign keys

| Table | Columns (in addition to audit columns) | Keys and relationships |
|---|---|---|
| `dbo.Book` | `BookID int IDENTITY(1,1)`, `Title nvarchar(300)` | PK `BookID`; one row per lendable item, even when titles repeat. |
| `dbo.Author` | `AuthorID int IDENTITY(1,1)`, `AuthorName nvarchar(200)` | PK `AuthorID`; names need not be unique. |
| `dbo.BookAuthor` | `BookAuthorID int IDENTITY(1,1)`, `BookID int`, `AuthorID int` | PK `BookAuthorID`; alternate UNIQUE key `(BookID, AuthorID)` prevents duplicate associations; FKs to `dbo.Book(BookID)` and `dbo.Author(AuthorID)`. |
| `dbo.Member` | `MemberID int IDENTITY(1,1)`, `MemberName nvarchar(200)` | PK `MemberID`; names need not be unique. |
| `dbo.BookLoan` | `BookLoanID int IDENTITY(1,1)`, `BookID int`, `MemberID int`, `LoanDate date`, `DueDate date`, `ReturnDate date NULL` | PK `BookLoanID`; FKs to `dbo.Book(BookID)` and `dbo.Member(MemberID)`. |

`BookAuthor` implements many-to-many authorship. Books and members each have zero or
more historical loans. All foreign keys use `NO ACTION` for updates and deletes,
preserving loan history and preventing orphaned rows.

## Two additional integrity rules (beyond keys and foreign keys)

1. `CK_BookLoan_DateOrder`: CHECK (`DueDate >= LoanDate AND (ReturnDate IS NULL OR ReturnDate >= LoanDate)`).
2. `UX_BookLoan_ActiveBook`: filtered UNIQUE index on `dbo.BookLoan(BookID)` WHERE
   `ReturnDate IS NULL`, allowing only one active loan per lendable item.

Dates are date-only; NULL `ReturnDate` means active. Returns after the due date are valid.
No other business constraints or indexes are proposed.

## Implementation sequence (separate task)

Create tables, keys, foreign keys, and the two rules. Validate multi-author books,
repeated historical loans, and rejection of duplicate author links, invalid date
order, orphaned references, and overlapping active loans.
