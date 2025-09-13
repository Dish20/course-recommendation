-- Students table
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    enrolled_on DATE DEFAULT '2025-01-01'
);

INSERT INTO Students (student_id, name, email) VALUES
(1, 'Alice Kumar', 'alice@example.com'),
(2, 'Bob Singh', 'bob@example.com'),
(3, 'Chitra Nair', 'chitra@example.com');

-- Courses table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    title VARCHAR(200),
    description TEXT,
    created_on DATE DEFAULT '2024-09-11'
);

INSERT INTO Courses (course_id, title, description) VALUES
(101, 'Intro to Data Science', 'Data basics'),
(102, 'Advanced Python', 'Generators, async'),
(103, 'Machine Learning 101', 'Supervised learning');

-- Enrollments table (student ↔ course)
CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enrolled_on DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

INSERT INTO Enrollments (enrollment_id, student_id, course_id) VALUES
(1001, 1, 101),
(1002, 1, 102),
(1003, 2, 101),
(1004, 2, 103),
(1005, 3, 101);

-- Progress table (percentage completed)
CREATE TABLE Progress (
    progress_id INT PRIMARY KEY,
    enrollment_id INT UNIQUE,
    percentage DECIMAL(5,2) CHECK (percentage >= 0 AND percentage <= 100),
    updated_at DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(enrollment_id)
);

INSERT INTO Progress (progress_id, enrollment_id, percentage, updated_at) VALUES
(2001, 1001, 80.0, '2025-08-01'),
(2002, 1002, 50.0, '2025-08-20'),
(2003, 1003, 10.0, '2025-07-10'),
(2004, 1004, 90.0, '2025-08-28'),
(2005, 1005, 5.0,  '2025-07-01');

-- Quiz scores (multiple attempts per enrollment)
CREATE TABLE QuizScores (
    quiz_id INT PRIMARY KEY,
    enrollment_id INT,
    score DECIMAL(5,2) CHECK (score >= 0 AND score <= 100),
    attempted_on DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(enrollment_id)
);

INSERT INTO QuizScores (quiz_id, enrollment_id, score, attempted_on) VALUES
(3001, 1001, 85.0, '2025-08-01'),
(3002, 1001, 90.0, '2025-08-10'),
(3003, 1002, 60.0, '2025-08-21'),
(3004, 1003, 40.0, '2025-07-11'),
(3005, 1004, 95.0, '2025-08-29');

---avg completion percentage per course
SELECT 
    c.course_id,
    c.title,
    ROUND(AVG(p.percentage), 2) AS avg_completion,
    COUNT(e.enrollment_id) AS total_enrolled
FROM Courses c
LEFT JOIN Enrollments e ON c.course_id = e.course_id
LEFT JOIN Progress p ON e.enrollment_id = p.enrollment_id
GROUP BY c.course_id, c.title
ORDER BY c.course_id;

----- Top 5 courses by engagement score

WITH course_stats AS (
    SELECT 
        c.course_id,
        c.title,
        COALESCE(AVG(p.percentage),0) AS avg_progress,
        COUNT(DISTINCT e.enrollment_id) AS enrolled_count,
        COALESCE(COUNT(q.quiz_id) * 1.0 / NULLIF(COUNT(DISTINCT e.enrollment_id),0),0) AS avg_quiz_attempts
    FROM Courses c
    LEFT JOIN Enrollments e ON c.course_id = e.course_id
    LEFT JOIN Progress p ON e.enrollment_id = p.enrollment_id
    LEFT JOIN QuizScores q ON e.enrollment_id = q.enrollment_id
    GROUP BY c.course_id, c.title
)

SELECT 
    course_id,
    title,
    ROUND(avg_progress,2) AS avg_progress,
    enrolled_count,
    ROUND(avg_quiz_attempts,2) AS avg_quiz_attempts,
    ROUND(avg_progress * LN(1+enrolled_count) + avg_quiz_attempts*2,2) AS engagement_score
FROM course_stats
ORDER BY engagement_score DESC
LIMIT 5;




