create database newwLibrary;
Use newwLibrary
create table Books(
BookID Int Primary KEY,
Title VARCHAR(50),
Author VARCHAR(50),
CopiesAvailable INT,
TotalCopies INT

);
CREATE TABLE Members (
    MemberID INT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Email VARCHAR(50) NOT NULL,
    TotalBooksBorrowed INT DEFAULT 0,
    IsActive BIT DEFAULT 1  
);
CREATE TABLE BorrowedBooks (
    BorrowID INT PRIMARY KEY,
    MemberID INT REFERENCES Members(MemberID), 
    BookID INT REFERENCES Books(BookID),   
    DueDate DATE,
    ReturnDate DATE,
    IsReturned BIT  
);

-- Stored Procedure: BorrowBook
CREATE PROCEDURE BorrowBook
    @MemberID INT,
    @BookID INT,
    @DueDate DATE
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @is_active BIT;
    DECLARE @CopiesAvailable INT;

    -- Check if the member is active
    SELECT @is_active = IsActive 
    FROM Members 
    WHERE MemberID = @MemberID;

    IF @is_active IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Member does not exist.', 16, 1);
        RETURN;
    END

    IF @is_active = 0
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Member is not active.', 16, 1);
        RETURN;
    END

    -- Check if the book has available copies
    SELECT @CopiesAvailable = CopiesAvailable 
    FROM Books 
    WHERE BookID = @BookID;

    IF @CopiesAvailable IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Book does not exist.', 16, 1);
        RETURN;
    END

    IF @CopiesAvailable <= 0
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('The book has no available copies.', 16, 1);
        RETURN;
    END

    -- Insert a new record into BorrowedBooks
    INSERT INTO BorrowedBooks (BorrowID, MemberID, BookID, DueDate, ReturnDate, IsReturned)
    VALUES (
        (SELECT ISNULL(MAX(BorrowID), 0) + 1 FROM BorrowedBooks),
        @MemberID,
        @BookID,
        @DueDate,
        NULL,
        0
    );

    -- Update the book's available copies
    UPDATE Books
    SET CopiesAvailable = CopiesAvailable -1
    WHERE BookID = @BookID;

    -- Update member's total borrowed count
    UPDATE Members
    SET TotalBooksBorrowed = TotalBooksBorrowed + 1
    WHERE MemberID = @MemberID;

    COMMIT TRANSACTION;
END;


-- Index
CREATE INDEX index_BookID
ON Books(BookID);

CREATE INDEX Index_MemberID
ON Members(MemberID);

-- Because BookID and MemberID are primary keys and are frequently used in lookups, joins, and conditions
-- making indexing essential for fast access and query optimization.



--Create a scalar function that takes a MemberID and returns the number of books currently
-- borrowed and not yet returned by that member.
CREATE FUNCTION GetBooksBorrowed (@MemberID INT)
RETURNS INT
AS
BEGIN
    DECLARE @BorrowedCount INT;

    SELECT @BorrowedCount = COUNT(*)
    FROM BorrowedBooks
    WHERE MemberID = @MemberID AND IsReturned = 0;

    RETURN @BorrowedCount;
END;

-- Write a BEFORE INSERT trigger on BorrowedBooks that prevents borrowing if:
-- CopiesAvailable = 0
-- OR IsActive = false
-- Raise a clear error message if validation fails.

CREATE TRIGGER PreventBorrowIfNoCopies
ON BorrowedBooks
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MemberID INT;
    DECLARE @BookID INT;

    SELECT @MemberID = MemberID, @BookID = BookID
    FROM inserted;

    -- Check member active status
    IF EXISTS (
        SELECT 1
        FROM Members
        WHERE MemberID = @MemberID AND IsActive = 0
    )
    BEGIN
        RAISERROR('you are not an active member, you cannot borrow book.', 16, 1);
        RETURN;
    END

    -- Check book availability
    IF EXISTS (
        SELECT 1
        FROM Books
        WHERE BookID = @BookID AND CopiesAvailable <= 0
    )
    BEGIN
        RAISERROR('Cannot borrow book. No copies available.', 16, 1);
        RETURN;
    END

    -- If all checks pass,proceed with insert
    INSERT INTO BorrowedBooks (BorrowID, MemberID, BookID, DueDate, ReturnDate, IsReturned)
    SELECT BorrowID, MemberID, BookID, DueDate, ReturnDate, IsReturned
    FROM inserted;
END;


INSERT INTO Books (BookID, Title, Author, CopiesAvailable, TotalCopies)
VALUES 
(1, 'first book', 'author 1', 3, 3),
(2, 'second book', 'author 2', 2, 2),
(3, 'third book', 'author 3', 1, 1);

INSERT INTO Members (MemberID, Name, Email, IsActive)
VALUES 
(101, 'Member 1', 'member1@gmail.com', 1),
(102, 'Member 2', 'member2@gmail.com', 1),
(103, 'Membern 3', 'member3@gmail.com', 0); -- Inactive Member

EXEC BorrowBook @MemberID = 101, @BookID = 1, @DueDate = '2025-05-01';
EXEC BorrowBook @MemberID = 102, @BookID = 1, @DueDate = '2025-05-02';
EXEC BorrowBook @MemberID = 101, @BookID = 2, @DueDate = '2025-05-03';
EXEC BorrowBook @MemberID = 103, @BookID = 2, @DueDate = '2025-05-04'; --inactive member
EXEC BorrowBook @MemberID = 102, @BookID = 3, @DueDate = '2025-05-05';