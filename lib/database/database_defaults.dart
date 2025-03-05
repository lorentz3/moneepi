String insertDefaultAccountsQuery = """  
        INSERT INTO Accounts (icon, name, sort) VALUES
        ('🏦', 'Bank account', 0),
        ('💵', 'Cash', 0),
        ('💳', 'Credit card', 0);
      """;

String insertDefaultExpenseCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type) VALUES
        ('🏠', 'House', 'EXPENSE'),
        ('🚘', 'Car', 'EXPENSE'),
        ('🍝', 'Food', 'EXPENSE'),
        ('👖', 'Clothes', 'EXPENSE'),
        ('💊', 'Health', 'EXPENSE'),
        ('🛁', 'Personal care', 'EXPENSE'),
        ('🏋️', 'Gym', 'EXPENSE'),
        ('📱', 'Cellphone', 'EXPENSE'),
        ('🎱', 'Leisure', 'EXPENSE'),
        ('✈️', 'Vacation', 'EXPENSE'),
        ('💻', 'Tech', 'EXPENSE'),
        ('📗', 'Education', 'EXPENSE'),
        ('🎁', 'Gifts', 'EXPENSE');
      """;

String insertDefaultIncomeCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type) VALUES
        ('🏭', 'Salary', 'INCOME'),
        ('💰', 'Refund', 'INCOME');
      """;