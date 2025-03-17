Map<int, List<String>> migrationScripts = {
    0: [
      """  
        CREATE TABLE Accounts (
          id INTEGER PRIMARY KEY,
          icon TEXT,
          name TEXT NOT NULL,
          initialBalance REAL NOT NULL DEFAULT 0,
          sort INTEGER NOT NULL DEFAULT 0);
      """,
      """
        CREATE TABLE Categories (
          id INTEGER PRIMARY KEY,
          icon TEXT,
          name TEXT NOT NULL,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          sort INTEGER NOT NULL DEFAULT 0,
          monthThreshold REAL,
          yearThreshold REAL);
      """,
      """  
        CREATE TABLE Transactions (
          id INTEGER PRIMARY KEY,
          type TEXT CHECK(type IN ('EXPENSE', 'INCOME', 'TRANSFER')) NOT NULL DEFAULT 'EXPENSE',
          timestamp INTEGER NOT NULL,
          categoryId INTEGER NULL,
          sourceAccountId INTEGER NULL,
          accountId INTEGER NOT NULL,
          amount REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY(accountId) REFERENCES Accounts(id),
          FOREIGN KEY(sourceAccountId) REFERENCES Accounts(id),
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
          cumulativeBalance REAL NOT NULL,
          PRIMARY KEY(accountId, month, year),
          FOREIGN KEY(accountId) REFERENCES Accounts(id));
      """
    ],
    3: [
      """  
        CREATE TABLE Groups (
          id INTEGER PRIMARY KEY,
          icon TEXT,
          name TEXT NOT NULL,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          sort INTEGER NOT NULL DEFAULT 0,
          monthThreshold REAL,
          yearThreshold REAL);
      """,
      """  
        CREATE TABLE Categories_Groups (
          groupId INTEGER NOT NULL,
          categoryId INTEGER NOT NULL,
          PRIMARY KEY(groupId, categoryId),
          FOREIGN KEY(groupId) REFERENCES Groups(id),
          FOREIGN KEY(categoryId) REFERENCES Categories(id));
      """,
    ],
  };