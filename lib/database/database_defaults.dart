String insertDefaultAccountsQuery = """  
        INSERT INTO Accounts (icon, name, sort) VALUES
        ('💵', 'My Bank', 1);
      """;

String insertDefaultExpenseCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type, sort) VALUES
        ('🛍️', 'Groceries', 'EXPENSE', 1),
        ('🍕', 'Eating out', 'EXPENSE', 2),
        ('🍟', 'Takeaway', 'EXPENSE', 3),
        ('🚘', 'Car', 'EXPENSE', 4),
        ('🛁', 'Personal care', 'EXPENSE', 5),
        ('💊', 'Pharmacy', 'EXPENSE', 6),
        ('📱', 'Cellphone', 'EXPENSE', 7),
        ('🎱', 'Leisure', 'EXPENSE', 8),
        ('🏠', 'Rent', 'EXPENSE', 9),
        ('⚡', 'Electricity bill', 'EXPENSE', 10),
        ('🔥', 'Gas bill', 'EXPENSE', 11),
        ('💧', 'Water bill', 'EXPENSE', 12),
        ('🌐', 'Internet', 'EXPENSE', 13),
        ('🗑️', 'Garbage tax', 'EXPENSE', 14),
        ('👖', 'Clothes', 'EXPENSE', 15),
        ('🩺', 'Medical consultation', 'EXPENSE', 16),
        ('🦷', 'Dentist', 'EXPENSE', 17),
        ('🏡', 'Household items', 'EXPENSE', 18),
        ('✈️', 'Vacation', 'EXPENSE', 19),
        ('🚅', 'Transportation', 'EXPENSE', 20),
        ('💻', 'Tech', 'EXPENSE', 21),
        ('📗', 'Education', 'EXPENSE', 22),
        ('🎁', 'Gifts & Donations', 'EXPENSE', 23);
      """;

String insertDefaultIncomeCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type, sort) VALUES
        ('💰', 'Salary', 'INCOME', 1);
      """;