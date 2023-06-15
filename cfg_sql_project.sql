#create database
CREATE DATABASE art_school;

USE art_school;

#create tables
CREATE TABLE classes (
	class_id VARCHAR(10) NOT NULL PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL,
    day VARCHAR(20) NOT NULL,
    class_fee INT NOT NULL,
    instructor_id VARCHAR(10) NOT NULL,
    material_id VARCHAR(10));
    
CREATE TABLE instructors (
	instructor_id VARCHAR(10) NOT NULL PRIMARY KEY,
    instructor_first_name VARCHAR(50) NOT NULL,
    instructor_last_name VARCHAR(50) NOT NULL);
    
CREATE TABLE students (
	student_id VARCHAR(10) NOT NULL PRIMARY KEY,
    student_first_name VARCHAR(50) NOT NULL,
    student_last_name VARCHAR(50) NOT NULL,
    contact_method VARCHAR(50),
    class_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (class_id) REFERENCES classes(class_id));
    
CREATE TABLE materials (
	material_id VARCHAR(50) NOT NULL PRIMARY KEY,
    material_name VARCHAR(50) NOT NULL,
    material_cost INT);
    
CREATE TABLE transactions (
	transaction_id VARCHAR(10) NOT NULL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    payment_date DATE NOT NULL,
    payment_amount FLOAT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id));
    
ALTER TABLE classes
	ADD CONSTRAINT class_instructor
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id);

ALTER TABLE classes
	ADD CONSTRAINT class_material
    FOREIGN KEY (material_id) REFERENCES materials(material_id);
  
#insert data
INSERT INTO instructors 
    VALUES 
    ("I1", "Marge", "Simpson"),
    ("I2", "Seymour", "Skinner"),
    ("I3", "Waylon", "Smithers"),
    ("I4", "Troy", "McClure"),
    ("I5", "Selma", "Bouvier");
    
INSERT INTO materials
	VALUES
    ("M1", "Painting Supplies", 50),
    ("M2", "Clay", 20),
    ("M3", "Drawing Supplies", 30),
    ("M4", "Camera Rental", 100);

INSERT INTO classes
    VALUES 
    ("C1", "Painting", "Monday", 120, "I1", "M1"),
    ("C2", "Advanced Painting", "Thursday", 120, "I1", "M1"),
    ("C3", "Ceramics", "Monday", 150, "I2", "M2"),
    ("C4", "Drawing", "Wednesday", 100, "I5", "M3"),
    ("C5", "Singing", "Friday", 25, "I3", NULL),
    ("C6", "Drama", "Tuesday", 40, "I4", NULL),
    ("C7", "Photography", "Thursday", 85, "I3", "M4"),
    ("C8", "Ceramics", "Wednesday", 150, "I2", "M2");

INSERT INTO students
	VALUES
	('S1', 'Lisa', 'Simpson', 'phone', 'C8'),
	('S2','Barney','Gumble','email','C1'),
	('S3','Abe','Simpson','phone','C2'),
	('S4','Edna','Krabapple','email','C7'),
	('S5','Ned','Flanders','email','C6'),
	('S6','Milhouse','Van Houten','text','C3'),
	('S7','Ralph','Wiggum','post','C5'),
	('S8','Joe','Quimby','email','C4'),
	('S9','Fat Tony','D''Amico','email','C4'),
	('S10','Sideshow','Bob','text','C6'),
	('S11','Kang','Johnson','phone','C6'),
	('S12','Kodos','Johnson','phone','C6'),
	('S13','Helen','Lovejoy','email','C7'),
	('S14','Lionel','Hutz','email','C1'),
	('S15','Montgomery','Burns','text','C1');

INSERT INTO transactions
	VALUES
  ('T1','S1','2023-03-01',170),
  ('T2','S2','2023-03-02',170),
  ('T3','S3','2023-03-03',120),
  ('T4','S4','2023-03-04',185),
  ('T5','S5','2023-03-05',40),
  ('T6','S7','2023-03-06',25),
  ('T7','S8','2023-03-07',100),
  ('T8','S9','2023-03-08',130),
  ('T9','S11','2023-03-09',40),
  ('T10','S12','2023-03-10',40),
  ('T11','S14','2023-03-11',120),
  ('T12','S15','2023-03-12',200);

#example queries, subsqueries & joins
#who is in Drama
SELECT s.student_first_name
FROM students AS s
WHERE s.class_id IN (
	SELECT c.class_id
    FROM classes AS c
    WHERE c.class_name = "Drama");
    
#all students & contact method of a specific teacher
SELECT s.student_first_name, s.student_last_name, s.contact_method, s.class_id
FROM students AS s
WHERE s.class_id IN (
	SELECT c.class_id
    FROM classes AS c
    WHERE c.instructor_id IN (
		SELECT i.instructor_id
		FROM instructors AS i
		WHERE i.instructor_id = "I1"));


SELECT * FROM instructors;
SELECT * FROM classes;



#stored function, procedure, joins
#how much do each student owe (fees + materials)
SELECT s.student_id, c.class_id, c.class_fee, IFNULL(m.material_cost, "none") AS material_cost
	FROM classes AS c
	LEFT JOIN materials AS m
	ON c.material_id = m.material_id
		JOIN students AS s
        ON s.class_id = c.class_id;
        
#have students paid all their fees?
CREATE TABLE money_owed 
	SELECT s.student_id, c.class_id, c.class_fee, IFNULL(m.material_cost, 0) AS material_cost
	FROM classes AS c
	LEFT JOIN materials AS m
	ON c.material_id = m.material_id
		JOIN students AS s
        ON s.class_id = c.class_id;

ALTER TABLE money_owed
	ADD total_owed INT;
    
ALTER TABLE money_owed
	ADD FOREIGN KEY (student_id) REFERENCES students(student_id);

SET SQL_SAFE_UPDATES = 0;

UPDATE money_owed
	SET total_owed = (class_fee + material_cost);
    
SELECT * FROM money_owed;

CREATE VIEW vw_payments AS (
	SELECT mo.student_id, mo.total_owed, IFNULL(t.payment_amount, 0) AS payment_amount
    FROM money_owed AS mo
    LEFT JOIN transactions AS t
    ON t.student_id = mo.student_id);
    
SELECT * FROM vw_payments;

DELIMITER //
CREATE FUNCTION fees_paid(payment_amount FLOAT, total_owed FLOAT)
RETURNS varchar(20)
deterministic
BEGIN
	DECLARE balance_paid VARCHAR(20);
	IF payment_amount > total_owed THEN SET balance_paid = "Overpaid";
    ELSEIF payment_amount = total_owed THEN SET balance_paid = "Paid";
    ELSEIF payment_amount < total_owed THEN SET balance_paid = "Balance Due";
    END IF;
RETURN(balance_paid);
END//fees_paid
DELIMITER ;

SELECT 
	student_id, 
    payment_amount,
    total_owed,
    fees_paid(payment_amount, total_owed) AS fees_paid
FROM vw_payments;

#stored procedure
DELIMITER //
CREATE PROCEDURE
change_contact(
	IN new_contact VARCHAR(50),
    IN in_student_id VARCHAR(10))
BEGIN
	UPDATE students
    SET contact_method = new_contact
    WHERE student_id = in_student_id;
END //
DELIMITER ;

CALL change_contact("Text", "S15");

SELECT * FROM students;




#multiple table view
CREATE VIEW vw_class_info AS (
	SELECT c.class_id, c.class_name, IFNULL(c.material_id, "none") AS material_id, IFNULL(m.material_name, "none") AS supplies, c.instructor_id, i.instructor_first_name, i.instructor_last_name
    FROM classes AS c
		LEFT JOIN instructors AS i
        ON c.instructor_id = i.instructor_id
			LEFT JOIN materials AS m
			ON c.material_id = m.material_id);
            
SELECT * FROM vw_class_info;

#table query - show classes with no materials needed
SELECT class_name 
FROM vw_class_info
WHERE supplies = "none";




#example query with group by and having
#classes with 3 or more students
SELECT COUNT(DISTINCT s.student_first_name) AS student_number, s.class_id
FROM students AS s
GROUP BY s.class_id
HAVING COUNT(s.class_id) >=3;

#group by and order by - find all students not taught by Marge and order by class
SELECT s.class_id, s.student_first_name, s.student_last_name, s.contact_method
FROM students AS s
WHERE s.class_id IN (
	SELECT c.class_id
    FROM classes AS c
    WHERE c.instructor_id IN (
		SELECT i.instructor_id
		FROM instructors AS i
		WHERE i.instructor_first_name != "Marge"))
GROUP BY s.class_id, s.student_first_name, s.student_last_name, s.contact_method
ORDER BY s.class_id ASC;

