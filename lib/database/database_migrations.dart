Map<int, List<String>> migrationScripts = {
    0: [
      """  
        CREATE TABLE Accounts (
          id INTEGER PRIMARY KEY,
          icon TEXT,
          name TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          sort INTEGER NOT NULL DEFAULT 0);
      """,
      """
        CREATE TABLE Categories (
          id INTEGER PRIMARY KEY,
          icon TEXT,
          name TEXT NOT NULL,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          sort INTEGER NOT NULL DEFAULT 0,
          parentId INTEGER,
          monthThreshold REAL,
          yearThreshold REAL,
          FOREIGN KEY(parentId) REFERENCES Categories(id));
      """,
      """  
        CREATE TABLE Transactions (
          id INTEGER PRIMARY KEY,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          timestamp INTEGER NOT NULL,
          accountId INTEGER NOT NULL,
          categoryId INTEGER NOT NULL,
          amount REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY(accountId) REFERENCES Accounts(id),
          FOREIGN KEY(categoryId) REFERENCES Categories(id));
      """
    ],
    1: [
      """  
        CREATE TABLE MonthlyCategoryTransactionSummaries (
          categoryId INTEGER NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          amount REAL NOT NULL,
          PRIMARY KEY(categoryId, month, year),
          FOREIGN KEY(categoryId) REFERENCES Categories(id));
      """
    ],
    2: [
      """  
        CREATE TABLE MonthlyAccountSummaries (
          accountId INTEGER NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          expenseAmount REAL NOT NULL,
          incomeAmount REAL NOT NULL,
          PRIMARY KEY(accountId, month, year),
          FOREIGN KEY(accountId) REFERENCES Accounts(id));
      """
    ]
  };