# 📚 Library Management Mini Project

## Task 1: Library Management System

### Objective
Design and implement a mini-library system to practice:
- Database design (ERD)
- Procedural SQL (Stored Procedures, Functions, Triggers)
- Indexing for performance

---

### Part 1: ERD and Requirements

Entities:
- **Books** (BookID, Title, Author, CopiesAvailable, TotalCopies)
- **Members** (MemberID, Name, Email, TotalBooksBorrowed, IsActive)
- **BorrowedBooks** (BorrowID, MemberID, BookID, BorrowDate, DueDate, ReturnDate, IsReturned)

ERD Requirements:
- Show entity relationships, cardinality, and participation (mandatory/optional).
- Avoid ER modeling traps (fan trap, chasm trap).

---

### Part 2: SQL Implementation

#### Stored Procedure: `BorrowBook`
- Check if member is active.
- Check if book has available copies.
- Insert into `BorrowedBooks` (IsReturned = false, DueDate = +14 days).
- Update `Books.CopiesAvailable` (decrease by 1).
- Update `Members.TotalBooksBorrowed` (increase by 1).

#### Indexes
- Create indexes on `Books(BookID)` and `Members(MemberID)`.

#### Function: `GetBooksBorrowed`
- Input: `MemberID`
- Output: Number of currently borrowed (not returned) books.

#### Trigger: `PreventBorrowIfNoCopies`
- Before Insert on `BorrowedBooks`.
- Block insert if `CopiesAvailable = 0` or `IsActive = false`.
- Raise clear error messages.

#### Sample Data
- Insert at least:
  - 3 books
  - 3 members
  - 5 borrow attempts

---

## Task 2: SQL Query → Relational Algebra

### Given Tables
- **STUDENT(StudentID, Name, Major, DeptID)**
- **COURSE(CourseID, Title, DeptID, Credits)**
- **ENROLLMENT(EnrollID, StudentID, CourseID, Grade)**

### SQL Query

```sql
SELECT S.Name, C.Title, E.Grade
FROM STUDENT S, COURSE C, ENROLLMENT E
WHERE S.StudentID = E.StudentID
AND C.CourseID = E.CourseID
AND S.Major = 'Computer Science'
AND C.Credits >= 3;
