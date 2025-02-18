Map<int, String> migrationScripts = {
    0: """  
        CREATE TABLE Accounts (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          sort INTEGER NOT NULL DEFAULT 0);
      """,
    1: """
        CREATE TABLE Categories (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          sort INTEGER NOT NULL DEFAULT 0,
          parentId INTEGER,
          monthThreshold REAL,
          yearThreshold REAL,
          FOREIGN KEY(parentId) REFERENCES Categories(id));
      """,
    2: """  
        CREATE TABLE Transactions (
          id INTEGER PRIMARY KEY,
          type TEXT CHECK(type IN ('EXPENSE','INCOME') ) NOT NULL DEFAULT 'EXPENSE',
          timestamp INTEGER NOT NULL,
          accountId INTEGER NOT NULL,
          categoryId INTEGER NOT NULL,
          amount REAL NOT NULL,
          notes TEXT,
          reimbursed REAL NOT NULL DEFAULT 0,
          FOREIGN KEY(accountId) REFERENCES Accounts(id),
          FOREIGN KEY(categoryId) REFERENCES Categories(id));
      """
  };