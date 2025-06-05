-- =====================================================
-- LIBRARY MANAGEMENT SYSTEM - TEST QUERIES
-- =====================================================
-- This file contains test queries to verify the database functionality

USE library_management;

-- =====================================================
-- BASIC FUNCTIONALITY TESTS
-- =====================================================

-- Test 1: Show all tables
SHOW TABLES;

-- Test 2: Count records in each table
SELECT 'authors' as table_name, COUNT(*) as record_count FROM authors
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'books', COUNT(*) FROM books
UNION ALL
SELECT 'members', COUNT(*) FROM members
UNION ALL
SELECT 'staff', COUNT(*) FROM staff
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'fines', COUNT(*) FROM fines;

-- =====================================================
-- VIEW TESTS
-- =====================================================

-- Test 3: Available books view
SELECT 'Available Books:' as test_name;
SELECT * FROM available_books LIMIT 5;

-- Test 4: Current loans view
SELECT 'Current Loans:' as test_name;
SELECT * FROM current_loans;

-- Test 5: Overdue loans view
SELECT 'Overdue Loans:' as test_name;
SELECT * FROM overdue_loans;

-- Test 6: Member statistics view
SELECT 'Member Statistics:' as test_name;
SELECT * FROM member_statistics;

-- =====================================================
-- RELATIONSHIP TESTS
-- =====================================================

-- Test 7: Books with their authors and categories
SELECT 'Books with Authors and Categories:' as test_name;
SELECT 
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') as authors,
    c.category_name,
    b.copies_available
FROM books b
JOIN categories c ON b.category_id = c.category_id
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title, c.category_name, b.copies_available
LIMIT 5;

-- Test 8: Members with their current loans
SELECT 'Members with Current Loans:' as test_name;
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) as member_name,
    m.membership_type,
    COUNT(l.loan_id) as active_loans,
    m.max_books_allowed
FROM members m
LEFT JOIN loans l ON m.member_id = l.member_id AND l.status = 'Active'
GROUP BY m.member_id, m.first_name, m.last_name, m.membership_type, m.max_books_allowed;

-- =====================================================
-- STORED PROCEDURE TESTS
-- =====================================================

-- Test 9: Test issuing a book (if member 5 has available slots)
SELECT 'Testing Book Issue:' as test_name;
SELECT 
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) as member_name,
    COUNT(l.loan_id) as current_loans,
    m.max_books_allowed,
    (m.max_books_allowed - COUNT(l.loan_id)) as available_slots
FROM members m
LEFT JOIN loans l ON m.member_id = l.member_id AND l.status = 'Active'
WHERE m.member_id = 5
GROUP BY m.member_id, m.first_name, m.last_name, m.max_books_allowed;

-- Check available books for issuing
SELECT 'Available Books for Issue:' as test_name;
SELECT book_id, title, copies_available 
FROM books 
WHERE copies_available > 0 
LIMIT 3;

-- =====================================================
-- CONSTRAINT TESTS
-- =====================================================

-- Test 10: Check foreign key constraints are working
SELECT 'Foreign Key Constraint Test:' as test_name;
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'library_management'
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- =====================================================
-- BUSINESS LOGIC TESTS
-- =====================================================

-- Test 11: Books that need to be returned soon (within 3 days)
SELECT 'Books Due Soon:' as test_name;
SELECT 
    l.loan_id,
    CONCAT(m.first_name, ' ', m.last_name) as member_name,
    b.title,
    l.due_date,
    DATEDIFF(l.due_date, CURRENT_DATE) as days_until_due
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN books b ON l.book_id = b.book_id
WHERE l.status = 'Active' 
AND l.due_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 3 DAY)
ORDER BY l.due_date;

-- Test 12: Most popular books (by loan count)
SELECT 'Most Popular Books:' as test_name;
SELECT 
    b.title,
    COUNT(l.loan_id) as total_loans,
    b.copies_total,
    ROUND((COUNT(l.loan_id) / b.copies_total), 2) as loans_per_copy
FROM books b
LEFT JOIN loans l ON b.book_id = l.book_id
GROUP BY b.book_id, b.title, b.copies_total
ORDER BY total_loans DESC
LIMIT 5;

-- Test 13: Member borrowing patterns
SELECT 'Member Borrowing Patterns:' as test_name;
SELECT 
    m.membership_type,
    COUNT(DISTINCT m.member_id) as total_members,
    COUNT(l.loan_id) as total_loans,
    ROUND(COUNT(l.loan_id) / COUNT(DISTINCT m.member_id), 2) as avg_loans_per_member
FROM members m
LEFT JOIN loans l ON m.member_id = l.member_id
GROUP BY m.membership_type
ORDER BY avg_loans_per_member DESC;

-- =====================================================
-- DATA INTEGRITY TESTS
-- =====================================================

-- Test 14: Check for data consistency
SELECT 'Data Consistency Check:' as test_name;

-- Check if any book has negative available copies
SELECT 'Books with negative availability:' as check_type, COUNT(*) as count
FROM books WHERE copies_available < 0
UNION ALL
-- Check if available copies exceed total copies
SELECT 'Books with availability > total:', COUNT(*)
FROM books WHERE copies_available > copies_total
UNION ALL
-- Check for loans without return date but marked as returned
SELECT 'Invalid returned loans:', COUNT(*)
FROM loans WHERE status = 'Returned' AND return_date IS NULL
UNION ALL
-- Check for active loans past due date
SELECT 'Active loans past due:', COUNT(*)
FROM loans WHERE status = 'Active' AND due_date < CURRENT_DATE;

-- =====================================================
-- PERFORMANCE TESTS
-- =====================================================

-- Test 15: Index usage verification
SELECT 'Index Usage Test:' as test_name;
EXPLAIN SELECT * FROM books WHERE isbn = '9780451524935';
EXPLAIN SELECT * FROM members WHERE membership_number = 'MEM001';
EXPLAIN SELECT * FROM loans WHERE member_id = 1 AND status = 'Active';

-- =====================================================
-- END OF TESTS
-- =====================================================

SELECT '=== ALL TESTS COMPLETED ===' as status;
