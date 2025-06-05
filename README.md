# 📚 Library Management System Database

## Project Overview

A comprehensive **Library Management System** built with MySQL that demonstrates advanced database design principles, relationships, constraints, and real-world functionality. This system manages books, members, staff, loans, reservations, and fines in a complete library environment.

## 🎯 Features

### Core Functionality
- **Book Management**: Complete catalog with ISBN, categories, authors, and inventory tracking
- **Member Management**: Different membership types with borrowing limits
- **Loan System**: Book borrowing with due dates, renewals, and return tracking
- **Reservation System**: Book reservation queue with priority levels
- **Fine Management**: Automatic fine calculation for overdue books
- **Staff Management**: Library staff with different roles and permissions

### Database Features
- **Relationships**: 1-to-1, 1-to-Many, Many-to-Many relationships
- **Constraints**: Primary Keys, Foreign Keys, CHECK, UNIQUE, NOT NULL
- **Views**: Pre-built queries for common operations
- **Stored Procedures**: Business logic for book issuing and returning
- **Triggers**: Automated actions for data integrity
- **Indexes**: Optimized performance for common queries

## 🗄️ Database Schema

### Tables Structure

1. **authors** - Author information and biography
2. **categories** - Book categories/genres
3. **books** - Main book inventory with availability tracking
4. **book_authors** - Many-to-many relationship between books and authors
5. **members** - Library members with different membership types
6. **staff** - Library employees with roles and permissions
7. **loans** - Book borrowing records with due dates
8. **reservations** - Book reservation queue
9. **fines** - Overdue fines and payment tracking

### Key Relationships
- **Books ↔ Authors**: Many-to-Many (via book_authors junction table)
- **Categories → Books**: One-to-Many
- **Members → Loans**: One-to-Many
- **Books → Loans**: One-to-Many
- **Staff → Loans**: One-to-Many
- **Members → Reservations**: One-to-Many
- **Loans → Fines**: One-to-Many

## 🚀 Setup Instructions

### Prerequisites
- MySQL Server 8.0 or higher
- MySQL Workbench or command line access

### Installation Steps

1. **Clone the repository**
   
   git clone <repository-url>
   cd database-8-assignment

2. **Import the database**
   
   **Option A: Using MySQL Workbench**
   - Open MySQL Workbench
   - Connect to your MySQL server
   - Go to File → Open SQL Script
   - Select `library_management_system.sql`
   - Execute the script

   **Option B: Using Command Line**

   mysql -u your_username -p < library_management_system.sql
   

3. **Verify Installation**

   USE library_management;
   SHOW TABLES;
   SELECT * FROM available_books;
   

## 📊 Entity Relationship Diagram (ERD)

┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   AUTHORS   │────│ BOOK_AUTHORS │────│    BOOKS    │
│             │    │              │    │             │
│ author_id   │    │ book_id      │    │ book_id     │
│ first_name  │    │ author_id    │    │ isbn        │
│ last_name   │    │ author_role  │    │ title       │
│ birth_date  │    └──────────────┘    │ category_id │
│ nationality │                        │ copies_total│
│ biography   │                        │ copies_avail│
└─────────────┘                        └─────────────┘
                                              │
                                              │
                                       ┌─────────────┐
                                       │ CATEGORIES  │
                                       │             │
                                       │ category_id │
                                       │ category_nm │
                                       │ description │
                                       └─────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   MEMBERS   │────│    LOANS    │────│    STAFF    │
│             │    │             │    │             │
│ member_id   │    │ loan_id     │    │ staff_id    │
│ membership# │    │ member_id   │    │ employee_id │
│ first_name  │    │ book_id     │    │ first_name  │
│ last_name   │    │ staff_id    │    │ last_name   │
│ email       │    │ loan_date   │    │ position    │
│ membership  │    │ due_date    │    │ salary      │
│ type        │    │ return_date │    └─────────────┘
│ status      │    │ status      │
└─────────────┘    └─────────────┘
      │                   │
      │                   │
      │            ┌─────────────┐
      │            │    FINES    │
      │            │             │
      │            │ fine_id     │
      │            │ loan_id     │
      │            │ member_id   │
      │            │ fine_amount │
      │            │ fine_reason │
      │            │ status      │
      │            └─────────────┘
      │
┌─────────────┐
│RESERVATIONS │
│             │
│reservation_id│
│ member_id   │
│ book_id     │
│ reservation │
│ date        │
│ expiry_date │
│ status      │
└─────────────┘


## 🔧 Usage Examples

### Basic Queries

**View all available books:**

SELECT * FROM available_books;


**Check current loans:**

SELECT * FROM current_loans;

**Find overdue books:**

SELECT * FROM overdue_loans;


**Member statistics:**

SELECT * FROM member_statistics WHERE member_id = 1;


### Using Stored Procedures

**Issue a book to a member:**

CALL IssueBook(member_id, book_id, staff_id, loan_days);
-- Example: CALL IssueBook(1, 5, 2, 14);

**Return a book:**

CALL ReturnBook(loan_id);
-- Example: CALL ReturnBook(1);

### Advanced Queries

**Books by category:**

SELECT c.category_name, COUNT(b.book_id) as book_count
FROM categories c
LEFT JOIN books b ON c.category_id = b.category_id
GROUP BY c.category_id, c.category_name;


**Most popular books:**

SELECT b.title, COUNT(l.loan_id) as loan_count
FROM books b
LEFT JOIN loans l ON b.book_id = l.book_id
GROUP BY b.book_id, b.title
ORDER BY loan_count DESC
LIMIT 10;


## 🧪 Testing

The database includes sample data for testing:
- 8 books across different categories
- 8 authors with biographical information
- 5 library members with different membership types
- 4 staff members with various roles
- Active loans and reservations
- Sample fines for overdue books

## 📈 Performance Features

- **Indexes** on frequently queried columns (ISBN, email, membership numbers)
- **Views** for complex queries to improve readability and performance
- **Constraints** to ensure data integrity
- **Triggers** for automated business logic

## 🔒 Security & Constraints

- Foreign key constraints prevent orphaned records
- Check constraints ensure valid data ranges
- Unique constraints prevent duplicate entries
- Triggers prevent invalid operations (e.g., deleting books with active loans)

## 🤝 Contributing

This is an educational project for database design learning. Feel free to:
- Add more sample data
- Create additional views for specific use cases
- Implement more stored procedures
- Add more sophisticated triggers

## 📝 License

This project is created for educational purposes as part of a database management course assignment.

---

**Author**: Database Assignment Week 8  
**Course**: Database Management Systems  
**Technology**: MySQL 8.0+
