
CREATE DATABASE CampusQ;

USE CampusQ;

CREATE TABLE `user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `user_type` enum('Student','Staff','Admin') NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
);

DESCRIBE `user`;

INSERT INTO `user` VALUES
  (1,'Alice Smith','alice.smith@university.edu','555-0101','Student'),
  (2,'Bob Jones','bob.jones@university.edu','555-0202','Student'),
  (3,'Charlie Brown','charlie.brown@university.edu','555-0303','Student'),
  (4,'Diana Prince','diana.prince@university.edu','555-0404','Student'),
  (5,'Evan Wright','evan.wright@university.edu','555-0505','Student'),
  (6,'Fiona Gallagher','fiona.g@university.edu','555-0606','Student'),
  (7,'George Clark','george.c@university.edu','555-0707','Student'),
  (8,'Hannah Abbott','hannah.a@university.edu','555-0808','Student'),
  (9,'Ian Malcolm','ian.m@university.edu','555-0909','Student'),
  (10,'Julia Roberts','julia.r@university.edu','555-1010','Student'),
  (11,'Dr. Robert Ford','robert.ford@university.edu','555-1111','Staff'),
  (12,'Dr. Bernard Lowe','bernard.lowe@university.edu','555-1212','Staff'),
  (13,'Theresa Cullen','theresa.cullen@university.edu','555-1313','Staff'),
  (14,'Charlotte Hale','charlotte.hale@university.edu','555-1414','Admin'),
  (15,'Lee Sizemore','lee.sizemore@university.edu','555-1515','Admin');

SELECT * FROM `user`;

CREATE TABLE `program` (
  `program_id` int NOT NULL AUTO_INCREMENT,
  `pr_id` varchar(50) NOT NULL,
  `program_name` varchar(100) NOT NULL,
  PRIMARY KEY (`program_id`),
  UNIQUE KEY `pr_id` (`pr_id`)
);

DESCRIBE `program`;

INSERT INTO `program` VALUES
  (1,'PRG-CS','Computer Science'),
  (2,'PRG-ENG','Software Engineering'),
  (3,'PRG-IT','Information Technology');

SELECT * FROM `program`;

CREATE TABLE `semester_policy` (
  `policy_id` int NOT NULL AUTO_INCREMENT,
  `policy_name` varchar(100) NOT NULL,
  `policy_details` text,
  PRIMARY KEY (`policy_id`)
);

DESCRIBE `semester_policy`;

INSERT INTO `semester_policy` VALUES
  (1,'Fall 2026 Payment Policy','All tuition and clearance fees must be cleared before mid-term exams.'),
  (2,'Spring 2026 Payment Policy','Partial payments allowed up to 50% before registration.');

SELECT * FROM `semester_policy`;

CREATE TABLE `queue_service` (
  `queue_service_id` int NOT NULL AUTO_INCREMENT,
  `qid` varchar(50) NOT NULL,
  `service_type` enum('Clearance','Financial Services','Queue Management') NOT NULL,
  `description` text,
  PRIMARY KEY (`queue_service_id`),
  UNIQUE KEY `qid` (`qid`)
);

DESCRIBE `queue_service`;

INSERT INTO `queue_service` VALUES
  (1,'QS-CLR','Clearance','End of semester clearance processing'),
  (2,'QS-FIN','Financial Services','Tuition payments and balance inquiries'),
  (3,'QS-MGT','Queue Management','General administrative queue requests');

SELECT * FROM `queue_service`;

CREATE TABLE `student` (
  `student_id` int NOT NULL,
  `sid` varchar(50) NOT NULL,
  `program_id` int DEFAULT NULL,
  PRIMARY KEY (`student_id`),
  UNIQUE KEY `sid` (`sid`),
  KEY `fk_student_program` (`program_id`),
  CONSTRAINT `fk_student_program` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`),
  CONSTRAINT `student_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
);

DESCRIBE `student`;

INSERT INTO `student` VALUES
  (1,'S1001',1),
  (2,'S1002',1),
  (3,'S1003',2),
  (4,'S1004',2),
  (5,'S1005',3),
  (6,'S1006',3),
  (7,'S1007',1),
  (8,'S1008',2),
  (9,'S1009',3),
  (10,'S1010',1);

SELECT * FROM `student`;

CREATE TABLE `staff` (
  `staff_id` int NOT NULL,
  `stid` varchar(50) NOT NULL,
  `department` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`staff_id`),
  UNIQUE KEY `stid` (`stid`),
  CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
);

DESCRIBE `staff`;

INSERT INTO `staff` VALUES
  (11,'ST2001','Financial Services'),
  (12,'ST2002','Registrar'),
  (13,'ST2003','Queue Management'),
  (14,'ST2004','Administration'),
  (15,'ST2005','IT Administration');

SELECT * FROM `staff`;

CREATE TABLE `admin` (
  `admin_id` int NOT NULL,
  `access_level` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`admin_id`),
  CONSTRAINT `admin_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `staff` (`staff_id`) ON DELETE CASCADE
);

DESCRIBE `admin`;

INSERT INTO `admin` VALUES
  (14,'SuperAdmin'),
  (15,'SystemAdmin');

SELECT * FROM `admin`;

CREATE TABLE `notification` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `nid` varchar(50) NOT NULL,
  `user_id` int NOT NULL,
  `message` text NOT NULL,
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`notification_id`),
  UNIQUE KEY `nid` (`nid`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
);

DESCRIBE `notification`;

INSERT INTO `notification` VALUES
  (1,'NOTIF-001',1,'Your payment has been successfully recorded.','2026-09-04 16:54:21',1),
  (2,'NOTIF-002',2,'Your payment has been registered.','2026-09-04 16:54:21',0),
  (3,'NOTIF-003',3,'Clearance request approved.','2026-09-04 16:54:21',1),
  (4,'NOTIF-004',4,'Queue request received.','2026-09-04 16:54:21',0),
  (5,'NOTIF-005',5,'Financial services ticket closed.','2026-09-04 16:54:21',1),
  (6,'NOTIF-006',6,'Document verification pending.','2026-09-04 16:54:21',0),
  (7,'NOTIF-007',7,'Semester policy update published.','2026-09-04 16:54:21',1),
  (8,'NOTIF-008',8,'Queue position updated: 3 remaining.','2026-09-04 16:54:21',0),
  (9,'NOTIF-009',9,'Clearance completed successfully.','2026-09-04 16:54:21',1),
  (10,'NOTIF-010',10,'Payment confirmation required.','2026-09-04 16:54:21',0),
  (11,'NOTIF-011',11,'New staff schedule assigned.','2026-09-04 16:54:21',1),
  (12,'NOTIF-012',12,'Queue service approval requested.','2026-09-04 16:54:21',0),
  (13,'NOTIF-013',13,'System maintenance scheduled.','2026-09-04 16:54:21',1),
  (14,'NOTIF-014',14,'Admin login detected from new device.','2026-09-04 16:54:21',0),
  (15,'NOTIF-015',15,'Database backup completed.','2026-09-04 16:54:21',1),
  (16,'NOTIF-016',1,'Reminder: Clear outstanding policies.','2026-09-04 16:54:21',0),
  (17,'NOTIF-017',2,'Queue service ticket is now in progress.','2026-09-04 16:54:21',1),
  (18,'NOTIF-018',3,'Program registration validated.','2026-09-04 16:54:21',1),
  (19,'NOTIF-019',4,'New notification settings applied.','2026-09-04 16:54:21',0),
  (20,'NOTIF-020',5,'Session timeout warning.','2026-09-04 16:54:21',1);

SELECT * FROM `notification`;

CREATE TABLE `payment` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `pid` varchar(50) NOT NULL,
  `student_id` int NOT NULL,
  `program_id` int NOT NULL,
  `policy_id` int DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `pid` (`pid`),
  KEY `student_id` (`student_id`),
  KEY `program_id` (`program_id`),
  KEY `policy_id` (`policy_id`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`),
  CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`),
  CONSTRAINT `payment_ibfk_3` FOREIGN KEY (`policy_id`) REFERENCES `semester_policy` (`policy_id`)
);

DESCRIBE `payment`;

INSERT INTO `payment` VALUES
  (1,'PAY-9001',1,1,1,1500.00,'2026-09-04 16:53:32'),
  (2,'PAY-9002',2,1,1,1200.00,'2026-09-04 16:53:32'),
  (3,'PAY-9003',3,2,1,1350.00,'2026-09-04 16:53:32'),
  (4,'PAY-9004',4,2,2,1400.00,'2026-09-04 16:53:32'),
  (5,'PAY-9005',5,3,2,1600.00,'2026-09-04 16:53:32'),
  (6,'PAY-9006',6,3,1,1500.00,'2026-09-04 16:53:32'),
  (7,'PAY-9007',7,1,2,1250.00,'2026-09-04 16:53:32'),
  (8,'PAY-9008',8,2,1,1300.00,'2026-09-04 16:53:32'),
  (9,'PAY-9009',9,3,2,1450.00,'2026-09-04 16:53:32'),
  (10,'PAY-9010',10,1,1,1550.00,'2026-09-04 16:53:32'),
  (11,'PAY-9011',1,1,2,500.00,'2026-09-04 16:53:32'),
  (12,'PAY-9012',2,1,2,600.00,'2026-09-04 16:53:32'),
  (13,'PAY-9013',3,2,2,450.00,'2026-09-04 16:53:32'),
  (14,'PAY-9014',4,2,1,700.00,'2026-09-04 16:53:32'),
  (15,'PAY-9015',5,3,1,800.00,'2026-09-04 16:53:32'),
  (16,'PAY-9016',6,3,2,550.00,'2026-09-04 16:53:32'),
  (17,'PAY-9017',7,1,1,900.00,'2026-09-04 16:53:32'),
  (18,'PAY-9018',8,2,2,650.00,'2026-09-04 16:53:32'),
  (19,'PAY-9019',9,3,1,750.00,'2026-09-04 16:53:32'),
  (20,'PAY-9020',10,1,2,500.00,'2026-09-04 16:53:32');

SELECT * FROM `payment`;

CREATE TABLE `queue_request` (
  `request_id` int NOT NULL AUTO_INCREMENT,
  `qid` varchar(50) NOT NULL,
  `student_id` int NOT NULL,
  `queue_service_id` int NOT NULL,
  `request_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(50) DEFAULT 'Pending',
  PRIMARY KEY (`request_id`),
  KEY `student_id` (`student_id`),
  KEY `queue_service_id` (`queue_service_id`),
  CONSTRAINT `queue_request_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`),
  CONSTRAINT `queue_request_ibfk_2` FOREIGN KEY (`queue_service_id`) REFERENCES `queue_service` (`queue_service_id`)
);

DESCRIBE `queue_request`;

INSERT INTO `queue_request` VALUES
  (1,'QR-101',1,1,'2026-09-04 16:53:42','Pending'),
  (2,'QR-102',2,2,'2026-09-04 16:53:42','In Progress'),
  (3,'QR-103',3,1,'2026-09-04 16:53:42','Approved'),
  (4,'QR-104',4,3,'2026-09-04 16:53:42','Pending'),
  (5,'QR-105',5,2,'2026-09-04 16:53:42','Completed'),
  (6,'QR-106',6,1,'2026-09-04 16:53:42','Pending'),
  (7,'QR-107',7,2,'2026-09-04 16:53:42','Approved'),
  (8,'QR-108',8,3,'2026-09-04 16:53:42','In Progress'),
  (9,'QR-109',9,1,'2026-09-04 16:53:42','Completed'),
  (10,'QR-110',10,2,'2026-09-04 16:53:42','Pending'),
  (11,'QR-111',1,3,'2026-09-04 16:53:42','Completed'),
  (12,'QR-112',2,1,'2026-09-04 16:53:42','Pending'),
  (13,'QR-113',3,2,'2026-09-04 16:53:42','Approved'),
  (14,'QR-114',4,1,'2026-09-04 16:53:42','In Progress'),
  (15,'QR-115',5,3,'2026-09-04 16:53:42','Completed'),
  (16,'QR-116',6,2,'2026-09-04 16:53:42','Pending'),
  (17,'QR-117',7,3,'2026-09-04 16:53:42','Approved'),
  (18,'QR-118',8,1,'2026-09-04 16:53:42','Completed'),
  (19,'QR-119',9,2,'2026-09-04 16:53:42','Pending'),
  (20,'QR-120',10,3,'2026-09-04 16:53:42','In Progress');

SELECT * FROM `queue_request`;

CREATE TABLE `queue_service_approval` (
  `approval_id` int NOT NULL AUTO_INCREMENT,
  `qid` varchar(50) NOT NULL,
  `request_id` int NOT NULL,
  `staff_id` int NOT NULL,
  `approval_status` varchar(50) DEFAULT 'Pending',
  `approval_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`approval_id`),
  KEY `request_id` (`request_id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `queue_service_approval_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `queue_request` (`request_id`),
  CONSTRAINT `queue_service_approval_ibfk_2` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`)
);

DESCRIBE `queue_service_approval`;

INSERT INTO `queue_service_approval` VALUES
  (1,'QA-501',1,11,'Pending','2026-09-04 16:56:27'),
  (2,'QA-502',2,12,'In Progress','2026-09-04 16:56:27'),
  (3,'QA-503',3,13,'Approved','2026-09-04 16:56:27'),
  (4,'QA-504',4,11,'Pending','2026-09-04 16:56:27'),
  (5,'QA-505',5,12,'Approved','2026-09-04 16:56:27'),
  (6,'QA-506',6,13,'Pending','2026-09-04 16:56:27'),
  (7,'QA-507',7,11,'Approved','2026-09-04 16:56:27'),
  (8,'QA-508',8,12,'In Progress','2026-09-04 16:56:27'),
  (9,'QA-509',9,13,'Approved','2026-09-04 16:56:27'),
  (10,'QA-510',10,11,'Pending','2026-09-04 16:56:27'),
  (11,'QA-511',11,12,'Approved','2026-09-04 16:56:27'),
  (12,'QA-512',12,13,'Pending','2026-09-04 16:56:27'),
  (13,'QA-513',13,11,'Approved','2026-09-04 16:56:27'),
  (14,'QA-514',14,12,'In Progress','2026-09-04 16:56:27'),
  (15,'QA-515',15,13,'Approved','2026-09-04 16:56:27'),
  (16,'QA-516',16,11,'Pending','2026-09-04 16:56:27'),
  (17,'QA-517',17,12,'Approved','2026-09-04 16:56:27'),
  (18,'QA-518',18,13,'Approved','2026-09-04 16:56:27'),
  (19,'QA-519',19,11,'Pending','2026-09-04 16:56:27'),
  (20,'QA-520',20,12,'In Progress','2026-09-04 16:56:27');

SELECT * FROM `queue_service_approval`;





-- Data Retrieval Assignemnt Queries on queue_request

-- 1. WHERE Clause: Which queue requests are currently pending approval?
SELECT request_id, student_id, request_time
FROM queue_request
WHERE status = 'Pending';

-- 2. BETWEEN Clause: Show all queue requests submitted between September 1, 2026, and September 7, 2026.
SELECT request_id, student_id, request_time, status
FROM queue_request
WHERE request_time BETWEEN '2026-09-01 00:00:00' AND '2026-09-07 23:59:59';

-- 3. LIKE Operator: Find queue requests whose queue identification code starts with 'QR-10'.
SELECT request_id, qid, student_id, status
FROM queue_request
WHERE qid LIKE 'QR-10%';

-- 4. IS NULL Clause: Which queue request records are still missing a status value?
SELECT request_id, qid, student_id
FROM queue_request
WHERE status IS NULL;

-- 5. ORDER BY with LIMIT: Show the 5 most recent queue requests submitted to the system.
SELECT request_id, qid, student_id, request_time
FROM queue_request
ORDER BY request_time DESC
LIMIT 5;

-- 6. GROUP BY with an Aggregate: How many total queue requests have been made for each queue service?
SELECT queue_service_id, COUNT(*) AS total_requests
FROM queue_request
GROUP BY queue_service_id;
