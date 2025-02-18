String insertDefaultAccountsQuery = """  
        INSERT INTO Accounts (name, sort) VALUES
        ('🏦 Bank account', 0),
        ('💵 Cash', 0),
        ('💳 Credit card', 0);
      """;

String insertDefaultCategoriesQuery = """  
        INSERT INTO Categories (name, type) VALUES
        ('🏠 House', 'EXPENSE'),
        ('🚘 Car', 'EXPENSE'),
        ('🏦 Food', 'EXPENSE'),
        ('🏦 Clothes', 'EXPENSE'),
        ('🏦 Health', 'EXPENSE'),
        ('🏦 Personal care', 'EXPENSE'),
        ('🏦 Gym', 'EXPENSE'),
        ('🏦 Cellphone', 'EXPENSE'),
        ('🏦 Leisure', 'EXPENSE'),
        ('🏦 Vacation', 'EXPENSE'),
        ('🏦 Insurance', 'EXPENSE'),
        ('🏦 Tech', 'EXPENSE'),
        ('🏦 Education', 'EXPENSE'),
        ('🏦 Gifts', 'EXPENSE');
      """;