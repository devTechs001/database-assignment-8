-- =====================================================
-- LIBRARY MANAGEMENT SYSTEM DATABASE
-- =====================================================
-- Author: Database Assignment Week 8
-- Description: Complete library management system with books, members, loans, and staff
-- Features: Full CRUD operations, relationships, constraints, views, procedures, triggers
-- =====================================================

-- Create database
DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management;
USE library_management;

-- =====================================================
-- TABLE CREATION WITH CONSTRAINTS
-- =====================================================

-- Authors table
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_author (first_name, last_name, birth_date)
);

-- Categories table
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Books table
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    publication_year YEAR,
    publisher VARCHAR(100),
    pages INT CHECK (pages > 0),
    copies_total INT DEFAULT 1 CHECK (copies_total > 0),
    copies_available INT DEFAULT 1 CHECK (copies_available >= 0),
    price DECIMAL(10,2) CHECK (price >= 0),
    location_shelf VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    INDEX idx_isbn (isbn),
    INDEX idx_title (title),
    INDEX idx_category (category_id)
);

-- Book-Author junction table (Many-to-Many relationship)
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    author_role ENUM('Primary Author', 'Co-Author', 'Editor', 'Translator') DEFAULT 'Primary Author',
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Members table
CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    membership_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    date_of_birth DATE,
    membership_date DATE DEFAULT (CURRENT_DATE),
    membership_type ENUM('Student', 'Faculty', 'Public', 'Senior') DEFAULT 'Public',
    status ENUM('Active', 'Suspended', 'Expired') DEFAULT 'Active',
    max_books_allowed INT DEFAULT 5 CHECK (max_books_allowed > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_membership_number (membership_number),
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Staff table
CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    position ENUM('Librarian', 'Assistant Librarian', 'Manager', 'IT Support') NOT NULL,
    hire_date DATE DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2) CHECK (salary > 0),
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loans table
CREATE TABLE loans (
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    staff_id INT NOT NULL,
    loan_date DATE DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('Active', 'Returned', 'Overdue', 'Lost') DEFAULT 'Active',
    renewal_count INT DEFAULT 0 CHECK (renewal_count >= 0),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE RESTRICT,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE RESTRICT,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE RESTRICT,
    INDEX idx_member_loan (member_id),
    INDEX idx_book_loan (book_id),
    INDEX idx_loan_status (status),
    INDEX idx_due_date (due_date)
);

-- Reservations table
CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date DATE DEFAULT (CURRENT_DATE),
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Active',
    priority_level INT DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    INDEX idx_member_reservation (member_id),
    INDEX idx_book_reservation (book_id),
    INDEX idx_reservation_status (status)
);

-- Fines table
CREATE TABLE fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    member_id INT NOT NULL,
    fine_amount DECIMAL(10,2) NOT NULL CHECK (fine_amount > 0),
    fine_reason VARCHAR(200) NOT NULL,
    fine_date DATE DEFAULT (CURRENT_DATE),
    payment_date DATE NULL,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE RESTRICT,
    INDEX idx_member_fine (member_id),
    INDEX idx_fine_status (status)
);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View: Available books with author and category information
CREATE VIEW available_books AS
SELECT
    b.book_id,
    b.isbn,
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    c.category_name,
    b.publication_year,
    b.publisher,
    b.copies_available,
    b.location_shelf
FROM books b
JOIN categories c ON b.category_id = c.category_id
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
WHERE b.copies_available > 0
GROUP BY b.book_id, b.isbn, b.title, c.category_name, b.publication_year, b.publisher, b.copies_available, b.location_shelf;

-- View: Current loans with member and book details
CREATE VIEW current_loans AS
SELECT
    l.loan_id,
    l.loan_date,
    l.due_date,
    DATEDIFF(l.due_date, CURRENT_DATE) AS days_until_due,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.membership_number,
    b.title AS book_title,
    b.isbn,
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    l.status,
    l.renewal_count
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN books b ON l.book_id = b.book_id
JOIN staff s ON l.staff_id = s.staff_id
WHERE l.status = 'Active';

-- View: Overdue loans
CREATE VIEW overdue_loans AS
SELECT
    l.loan_id,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    m.phone,
    b.title AS book_title,
    b.isbn
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN books b ON l.book_id = b.book_id
WHERE l.due_date < CURRENT_DATE AND l.status = 'Active';

-- View: Member statistics
CREATE VIEW member_statistics AS
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.membership_number,
    m.membership_type,
    COUNT(l.loan_id) AS total_loans,
    COUNT(CASE WHEN l.status = 'Active' THEN 1 END) AS current_loans,
    COUNT(CASE WHEN l.status = 'Overdue' THEN 1 END) AS overdue_loans,
    COALESCE(SUM(f.fine_amount), 0) AS total_fines,
    COALESCE(SUM(CASE WHEN f.status = 'Pending' THEN f.fine_amount ELSE 0 END), 0) AS pending_fines
FROM members m
LEFT JOIN loans l ON m.member_id = l.member_id
LEFT JOIN fines f ON m.member_id = f.member_id
GROUP BY m.member_id, m.first_name, m.last_name, m.membership_number, m.membership_type;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Procedure: Issue a book to a member
CREATE PROCEDURE IssueBook(
    IN p_member_id INT,
    IN p_book_id INT,
    IN p_staff_id INT,
    IN p_loan_days INT
)
BEGIN
    DECLARE v_available_copies INT;
    DECLARE v_member_current_loans INT;
    DECLARE v_member_max_books INT;
    DECLARE v_member_status VARCHAR(20);

    -- Check if member is active
    SELECT status, max_books_allowed INTO v_member_status, v_member_max_books
    FROM members WHERE member_id = p_member_id;

    IF v_member_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member account is not active';
    END IF;

    -- Check available copies
    SELECT copies_available INTO v_available_copies
    FROM books WHERE book_id = p_book_id;

    IF v_available_copies <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No copies available for this book';
    END IF;

    -- Check member's current loan count
    SELECT COUNT(*) INTO v_member_current_loans
    FROM loans WHERE member_id = p_member_id AND status = 'Active';

    IF v_member_current_loans >= v_member_max_books THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member has reached maximum book limit';
    END IF;

    -- Issue the book
    INSERT INTO loans (member_id, book_id, staff_id, due_date)
    VALUES (p_member_id, p_book_id, p_staff_id, DATE_ADD(CURRENT_DATE, INTERVAL p_loan_days DAY));

    -- Update available copies
    UPDATE books SET copies_available = copies_available - 1 WHERE book_id = p_book_id;

END //

-- Procedure: Return a book
CREATE PROCEDURE ReturnBook(
    IN p_loan_id INT
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_member_id INT;
    DECLARE v_days_overdue INT;

    -- Get loan details
    SELECT book_id, due_date, member_id INTO v_book_id, v_due_date, v_member_id
    FROM loans WHERE loan_id = p_loan_id AND status = 'Active';

    IF v_book_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid loan ID or book already returned';
    END IF;

    -- Update loan record
    UPDATE loans SET
        return_date = CURRENT_DATE,
        status = 'Returned'
    WHERE loan_id = p_loan_id;

    -- Update available copies
    UPDATE books SET copies_available = copies_available + 1 WHERE book_id = v_book_id;

    -- Calculate fine if overdue
    SET v_days_overdue = DATEDIFF(CURRENT_DATE, v_due_date);
    IF v_days_overdue > 0 THEN
        INSERT INTO fines (loan_id, member_id, fine_amount, fine_reason)
        VALUES (p_loan_id, v_member_id, v_days_overdue * 1.00, CONCAT('Overdue fine: ', v_days_overdue, ' days'));
    END IF;

END //

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger: Update loan status to overdue
CREATE TRIGGER update_overdue_loans
BEFORE UPDATE ON loans
FOR EACH ROW
BEGIN
    IF NEW.due_date < CURRENT_DATE AND NEW.status = 'Active' AND OLD.status = 'Active' THEN
        SET NEW.status = 'Overdue';
    END IF;
END //

-- Trigger: Prevent deletion of books with active loans
CREATE TRIGGER prevent_book_deletion
BEFORE DELETE ON books
FOR EACH ROW
BEGIN
    DECLARE v_active_loans INT;
    SELECT COUNT(*) INTO v_active_loans
    FROM loans WHERE book_id = OLD.book_id AND status IN ('Active', 'Overdue');

    IF v_active_loans > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete book with active loans';
    END IF;
END //

-- Trigger: Auto-update book availability when copies change
CREATE TRIGGER update_book_availability
BEFORE UPDATE ON books
FOR EACH ROW
BEGIN
    IF NEW.copies_available > NEW.copies_total THEN
        SET NEW.copies_available = NEW.copies_total;
    END IF;
    IF NEW.copies_available < 0 THEN
        SET NEW.copies_available = 0;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert Categories
INSERT INTO categories (category_name, description) VALUES
('Fiction', 'Fictional literature including novels and short stories'),
('Non-Fiction', 'Factual books including biographies, history, and science'),
('Science', 'Scientific literature and research'),
('Technology', 'Computer science, engineering, and technology books'),
('History', 'Historical books and documentaries'),
('Biography', 'Life stories of notable people'),
('Children', 'Books for children and young adults'),
('Reference', 'Dictionaries, encyclopedias, and reference materials');

-- Insert Authors
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography) VALUES
('George', 'Orwell', '1903-06-25', 'British', 'English novelist and journalist known for 1984 and Animal Farm'),
('Jane', 'Austen', '1775-12-16', 'British', 'English novelist known for Pride and Prejudice'),
('Stephen', 'King', '1947-09-21', 'American', 'American author of horror, supernatural fiction, and fantasy'),
('Agatha', 'Christie', '1890-09-15', 'British', 'English writer known for detective novels'),
('Isaac', 'Asimov', '1920-01-02', 'American', 'American writer and professor of biochemistry'),
('J.K.', 'Rowling', '1965-07-31', 'British', 'British author, best known for Harry Potter series'),
('Mark', 'Twain', '1835-11-30', 'American', 'American writer, humorist, and lecturer'),
('Charles', 'Dickens', '1812-02-07', 'British', 'English writer and social critic');

-- Insert Books
INSERT INTO books (isbn, title, category_id, publication_year, publisher, pages, copies_total, copies_available, price, location_shelf) VALUES
('9780451524935', '1984', 1, 1949, 'Penguin Books', 328, 5, 5, 12.99, 'A1-001'),
('9780141439518', 'Pride and Prejudice', 1, 1813, 'Penguin Classics', 432, 3, 3, 10.99, 'A1-015'),
('9780307474278', 'The Shining', 1, 1977, 'Anchor Books', 659, 4, 4, 15.99, 'B2-032'),
('9780062073488', 'Murder on the Orient Express', 1, 1934, 'William Morrow', 256, 2, 2, 13.99, 'B2-045'),
('9780553293357', 'Foundation', 3, 1951, 'Bantam Spectra', 244, 3, 3, 14.99, 'C3-012'),
('9780439708180', 'Harry Potter and the Sorcerers Stone', 7, 1997, 'Scholastic', 309, 8, 8, 8.99, 'D4-001'),
('9780486280615', 'Adventures of Huckleberry Finn', 1, 1884, 'Dover Publications', 366, 2, 2, 9.99, 'A1-089'),
('9780141439600', 'Great Expectations', 1, 1861, 'Penguin Classics', 544, 3, 3, 11.99, 'A1-156');

-- Insert Book-Author relationships
INSERT INTO book_authors (book_id, author_id, author_role) VALUES
(1, 1, 'Primary Author'),
(2, 2, 'Primary Author'),
(3, 3, 'Primary Author'),
(4, 4, 'Primary Author'),
(5, 5, 'Primary Author'),
(6, 6, 'Primary Author'),
(7, 7, 'Primary Author'),
(8, 8, 'Primary Author');

-- Insert Staff
INSERT INTO staff (employee_id, first_name, last_name, email, phone, position, salary) VALUES
('LIB001', 'Sarah', 'Johnson', 'sarah.johnson@library.com', '555-0101', 'Manager', 55000.00),
('LIB002', 'Michael', 'Brown', 'michael.brown@library.com', '555-0102', 'Librarian', 45000.00),
('LIB003', 'Emily', 'Davis', 'emily.davis@library.com', '555-0103', 'Assistant Librarian', 35000.00),
('LIB004', 'David', 'Wilson', 'david.wilson@library.com', '555-0104', 'Librarian', 45000.00);

-- Insert Members
INSERT INTO members (membership_number, first_name, last_name, email, phone, address, date_of_birth, membership_type, max_books_allowed) VALUES
('MEM001', 'John', 'Smith', 'john.smith@email.com', '555-1001', '123 Main St, City, State 12345', '1985-03-15', 'Public', 5),
('MEM002', 'Lisa', 'Anderson', 'lisa.anderson@email.com', '555-1002', '456 Oak Ave, City, State 12345', '1990-07-22', 'Student', 8),
('MEM003', 'Robert', 'Taylor', 'robert.taylor@email.com', '555-1003', '789 Pine Rd, City, State 12345', '1978-11-08', 'Faculty', 10),
('MEM004', 'Maria', 'Garcia', 'maria.garcia@email.com', '555-1004', '321 Elm St, City, State 12345', '1995-01-30', 'Student', 8),
('MEM005', 'James', 'Miller', 'james.miller@email.com', '555-1005', '654 Maple Dr, City, State 12345', '1965-09-12', 'Senior', 5);

-- Insert Sample Loans
INSERT INTO loans (member_id, book_id, staff_id, due_date, status) VALUES
(1, 1, 2, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY), 'Active'),
(2, 6, 3, DATE_ADD(CURRENT_DATE, INTERVAL 21 DAY), 'Active'),
(3, 5, 2, DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY), 'Active'),
(1, 3, 4, DATE_SUB(CURRENT_DATE, INTERVAL 5 DAY), 'Overdue'),
(4, 2, 3, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY), 'Active');

-- Update book availability based on loans
UPDATE books SET copies_available = copies_available - 1 WHERE book_id IN (1, 2, 3, 5, 6);

-- Insert Sample Reservations
INSERT INTO reservations (member_id, book_id, expiry_date, priority_level) VALUES
(5, 1, DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY), 1),
(4, 3, DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY), 2);

-- Insert Sample Fines
INSERT INTO fines (loan_id, member_id, fine_amount, fine_reason) VALUES
(4, 1, 5.00, 'Overdue fine: 5 days');

-- =====================================================
-- USEFUL QUERIES FOR TESTING
-- =====================================================

-- Show all available books
-- SELECT * FROM available_books;

-- Show current loans
-- SELECT * FROM current_loans;

-- Show overdue loans
-- SELECT * FROM overdue_loans;

-- Show member statistics
-- SELECT * FROM member_statistics;

-- Test issuing a book
-- CALL IssueBook(5, 4, 2, 14);

-- Test returning a book
-- CALL ReturnBook(1);

-- =====================================================
-- END OF LIBRARY MANAGEMENT SYSTEM DATABASE
-- =====================================================
