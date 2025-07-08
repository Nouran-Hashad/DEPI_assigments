-- 1. Create Database
CREATE DATABASE w3company;
USE w3company;

-- 2. Create Tables (Main + Relationship Tables)
CREATE TABLE Department (
    Dnumber INT PRIMARY KEY,
    Dname VARCHAR(20),
    Dlocation VARCHAR(20),
    Mng_ssn INT
);
ALTER TABLE Department
ALTER COLUMN Mng_ssn INT;

CREATE TABLE Employee (
    Ssn INT PRIMARY KEY,
    Fname VARCHAR(20),
    Lname VARCHAR(20),
    Birthdate DATE,
    Gender CHAR(1),
    Dnum INT,
    Super_ssn INT,
    FOREIGN KEY (Dnum) REFERENCES Department(Dnumber),
    FOREIGN KEY (Super_ssn) REFERENCES Employee(Ssn)
);

CREATE TABLE Project (
    Pnumber INT PRIMARY KEY,
    Pname VARCHAR(20),
    Location_city VARCHAR(20),
    Dnum INT,
    FOREIGN KEY (Dnum) REFERENCES Department(Dnumber)
);

CREATE TABLE Dependents (
    Essn INT,
    Dependent_name VARCHAR(20),
    Gender CHAR(1),
    Birthdate DATE,
    PRIMARY KEY(Essn, Dependent_name),
    FOREIGN KEY (Essn) REFERENCES Employee(Ssn)
);

CREATE TABLE Works_on (
    Essn INT,
    Pnum INT,
    Working_hours DECIMAL(10, 2),
    PRIMARY KEY(Essn, Pnum),
    FOREIGN KEY(Essn) REFERENCES Employee(Ssn),
    FOREIGN KEY(Pnum) REFERENCES Project(Pnumber)
);

CREATE TABLE Manage (
    Essn INT,
    Dnum INT,
    PRIMARY KEY(Essn, Dnum),
    FOREIGN KEY(Essn) REFERENCES Employee(Ssn),
    FOREIGN KEY(Dnum) REFERENCES Department(Dnumber)
);

--add foreign key constraint to department table 
ALTER TABLE Department
ADD CONSTRAINT Dep_fk FOREIGN KEY (Mng_ssn) REFERENCES Employee(Ssn);


-- 3. Insert Departments (initially with NULL manager to avoid FK error)
INSERT INTO Department (Dnumber, Dname, Dlocation, Mng_ssn)
VALUES 
(1, 'HR', 'Cairo', NULL),
(2, 'IT', 'Alexandria', NULL),
(3, 'Marketing', 'Giza', NULL),
(4, 'Finance', 'Tanta', NULL);

-- 4. Insert Employees (include future managers)
INSERT INTO Employee (Ssn, Fname, Lname, Birthdate, Gender, Dnum, Super_ssn)
VALUES
(1001, 'Ahmed', 'Hassan', '1990-05-15', 'M', 1, NULL),
(1002, 'Sara', 'Ali', '1995-08-20', 'F', 1, 1001),
(1003, 'Omar', 'Youssef', '1992-03-10', 'M', 2, NULL),
(1004, 'Nouran', 'Hashad', '1998-02-12', 'F', 3, 1001), 
(1005, 'Mohamed', 'Ibrahim', '1994-12-01', 'M', 3, 1004),
(1006, 'Alaa', 'Khaled', '1993-07-09', 'F', 4, 1003),
(1007, 'Hany', 'Salem', '1990-11-11', 'M', 4, NULL);

-- 5. Update Managers in Departments
UPDATE Department SET Mng_ssn = 1001 WHERE Dnumber = 1;
UPDATE Department SET Mng_ssn = 1003 WHERE Dnumber = 2;
UPDATE Department SET Mng_ssn = 1004 WHERE Dnumber = 3;
UPDATE Department SET Mng_ssn = 1007 WHERE Dnumber = 4;

-- 6. Insert Projects
INSERT INTO Project (Pnumber, Pname, Location_city, Dnum)
VALUES
(501, 'Website Dev', 'Cairo', 2),
(502, 'Recruitment', 'Cairo', 1),
(503, 'Marketing Campaign', 'Giza', 3),
(504, 'ERP System', 'Tanta', 4),
(505, 'Payroll Automation', 'Tanta', 4);

-- 7. Insert Dependents
INSERT INTO Dependents (Essn, Dependent_name, Gender, Birthdate)
VALUES
(1001, 'Youssef', 'M', '2015-06-10'),
(1002, 'Mona', 'F', '2018-09-22'),
(1004, 'Layla', 'F', '2020-01-01'),
(1005, 'Adam', 'M', '2017-03-03'),
(1006, 'Salma', 'F', '2014-06-06');

-- 8. Insert Work Assignments
INSERT INTO Works_on (Essn, Pnum, Working_hours)
VALUES
(1001, 502, 15.0),
(1002, 501, 25.5),
(1003, 501, 40.0),
(1004, 503, 35.0),
(1005, 503, 38.5),
(1006, 504, 20.0),
(1007, 504, 22.0),
(1007, 505, 18.0);

-- 9. Insert Manage Relationships
INSERT INTO Manage (Essn, Dnum)
VALUES
(1001, 1),
(1003, 2),
(1004, 3),
(1007, 4);

-- Retrieve all employees working in a specific department by name ('IT')
SELECT 
    E.Ssn,
    E.Fname,
    E.Lname,
    D.Dname AS Department
FROM 
    Employee E
JOIN Department D ON E.Dnum = D.Dnumber
WHERE 
    D.Dname = 'IT'; 

-- Find all employees and their project assignments with working hours
SELECT 
    E.Ssn,
    E.Fname,
    E.Lname,
    P.Pname AS Project_Name,
    W.Working_hours
FROM 
    Employee E
JOIN Works_on W ON E.Ssn = W.Essn
JOIN Project P ON W.Pnum = P.Pnumber
ORDER BY E.Ssn;
