String insertDefaultAccountsQuery = """  
        INSERT INTO Accounts (icon, name, sort) VALUES
        ('🏦', 'Bank account', 1),
        ('💵', 'Cash', 2),
        ('®️', 'Revolut', 3),
        ('💎', 'Paypal', 4),
        ('🉐', 'Edenred', 5);
      """;

String insertDefaultExpenseCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type, sort) VALUES
        ('🛍️', 'Groceries', 'EXPENSE', 1),
        ('🍕', 'Eating out', 'EXPENSE', 2),
        ('🍟', 'Takeaway', 'EXPENSE', 3),
        ('⛽', 'Gasoline', 'EXPENSE', 4),
        ('🚙', 'CNG', 'EXPENSE', 5),
        ('🅿️', 'Parking', 'EXPENSE', 6),
        ('🛣️', 'Toll', 'EXPENSE', 7),
        ('🛁', 'Personal care', 'EXPENSE', 8),
        ('💊', 'Pharmacy', 'EXPENSE', 9),
        ('📱', 'Cellphone', 'EXPENSE', 10),
        ('🎱', 'Leisure', 'EXPENSE', 11),
        ('🏠', 'Rent', 'EXPENSE', 12),
        ('⚡', 'Electricity bill', 'EXPENSE', 13),
        ('🔥', 'Gas bill', 'EXPENSE', 14),
        ('💧', 'Water bill', 'EXPENSE', 15),
        ('🌐', 'Internet', 'EXPENSE', 16),
        ('🗑️', 'Garbage tax', 'EXPENSE', 17),
        ('🔧', 'Car maintenance', 'EXPENSE', 18),
        ('🏎️', 'Car insurance', 'EXPENSE', 19),
        ('💸', 'Car tax', 'EXPENSE', 20),
        ('👖', 'Clothes', 'EXPENSE', 21),
        ('💆', 'Wellness', 'EXPENSE', 22),
        ('🏋️', 'Gym', 'EXPENSE', 23),
        ('🩺', 'Medical consultation', 'EXPENSE', 24),
        ('🦷', 'Dentist', 'EXPENSE', 25),
        ('🏡', 'Household items', 'EXPENSE', 26),
        ('✈️', 'Vacation', 'EXPENSE', 27),
        ('🚅', 'Transportation', 'EXPENSE', 28),
        ('💻', 'Tech', 'EXPENSE', 29),
        ('📗', 'Education', 'EXPENSE', 30),
        ('🎁', 'Gifts & Donations', 'EXPENSE', 31);
      """;

String insertDefaultIncomeCategoriesQuery = """  
        INSERT INTO Categories (icon, name, type, sort) VALUES
        ('🪙', 'Salary', 'INCOME', 1),
        ('💰', 'Refund', 'INCOME', 2),
        ('⚜️', 'Bonus', 'INCOME', 3);
      """;