-- ============================================================================

DROP DATABASE IF EXISTS campusq;
CREATE DATABASE campusq;

USE campusq;

-- ============================================================================
-- 1. REFERENCE TABLES
-- ============================================================================

CREATE TABLE program (
    program_id      INT AUTO_INCREMENT PRIMARY KEY,
    program_code    VARCHAR(20)     NOT NULL,
    program_name    VARCHAR(150)    NOT NULL,
    tuition_fee     DECIMAL(12,2)   NOT NULL,
    other_fees      DECIMAL(12,2)   NOT NULL DEFAULT 0,
    CONSTRAINT uq_program_code UNIQUE (program_code),
    CONSTRAINT chk_program_fees CHECK (tuition_fee >= 0 AND other_fees >= 0)
) ;

CREATE TABLE accommodation_tier (
    tier_id         INT AUTO_INCREMENT PRIMARY KEY,
    tier_name       VARCHAR(50)     NOT NULL,
    tier_fee        DECIMAL(12,2)   NOT NULL,
    CONSTRAINT uq_tier_name UNIQUE (tier_name),
    CONSTRAINT chk_tier_fee CHECK (tier_fee >= 0)
);


CREATE TABLE semester (
    semester_id     INT AUTO_INCREMENT PRIMARY KEY,
    term_code       VARCHAR(20)     NOT NULL,
    academic_year   VARCHAR(9)      NOT NULL,
    label           VARCHAR(50)     NOT NULL,
    CONSTRAINT uq_semester_term_year UNIQUE (term_code, academic_year)
);

CREATE TABLE staff (
    staff_id        INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50)     NOT NULL,
    full_name       VARCHAR(150)    NOT NULL,
    role            ENUM('Accounts','Admin') NOT NULL,
    CONSTRAINT uq_staff_username UNIQUE (username)
);


CREATE TABLE queue_service (
    service_id      INT AUTO_INCREMENT PRIMARY KEY,
    service_name    VARCHAR(100)    NOT NULL,
    service_type    ENUM('SchoolPay','Bank') NOT NULL,
    CONSTRAINT uq_service_name UNIQUE (service_name)
);



-- ============================================================================
-- 2. STUDENT IDENTITY (permanent) AND REGISTRATION (per-semester)
-- ============================================================================

CREATE TABLE student (
    reg_number      VARCHAR(20)     PRIMARY KEY,          -- e.g. M25B13/038, entered as-is
    access_number   VARCHAR(30)     NOT NULL,
    full_name       VARCHAR(150)    NOT NULL,
    program_id      INT             NOT NULL,
    CONSTRAINT uq_student_access_number UNIQUE (access_number),
    CONSTRAINT fk_student_program FOREIGN KEY (program_id)
        REFERENCES program (program_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE registration (
    registration_id         INT AUTO_INCREMENT PRIMARY KEY,
    student_reg_number      VARCHAR(20)     NOT NULL,
    semester_id              INT             NOT NULL,
    is_resident              BOOLEAN         NOT NULL DEFAULT FALSE,
    accommodation_tier_id    INT             NULL,
    CONSTRAINT uq_registration_student_semester UNIQUE (student_reg_number, semester_id),
    CONSTRAINT fk_registration_student FOREIGN KEY (student_reg_number)
        REFERENCES student (reg_number) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_registration_semester FOREIGN KEY (semester_id)
        REFERENCES semester (semester_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_registration_tier FOREIGN KEY (accommodation_tier_id)
        REFERENCES accommodation_tier (tier_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================================
-- 3. BILLING: INVOICE AND PAYMENT (with SchoolPay / Bank subtypes)
-- ============================================================================

CREATE TABLE invoice (
    invoice_id          INT AUTO_INCREMENT PRIMARY KEY,
    registration_id     INT             NOT NULL,
    amount_due          DECIMAL(12,2)   NOT NULL,
    amount_paid         DECIMAL(12,2)   NOT NULL DEFAULT 0,
    CONSTRAINT uq_invoice_registration UNIQUE (registration_id),
    CONSTRAINT fk_invoice_registration FOREIGN KEY (registration_id)
        REFERENCES registration (registration_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_invoice_amounts CHECK (amount_due >= 0 AND amount_paid >= 0)
);

CREATE TABLE payment (
    payment_id          INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id          INT             NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    payment_date        DATE            NOT NULL,
    payment_method      ENUM('SchoolPay','Bank') NOT NULL,
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice (invoice_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

CREATE TABLE schoolpay_payment (
    payment_id                  INT PRIMARY KEY,
    schoolpay_transaction_ref   VARCHAR(50)     NOT NULL,
    CONSTRAINT uq_schoolpay_ref UNIQUE (schoolpay_transaction_ref),
    CONSTRAINT fk_schoolpay_payment FOREIGN KEY (payment_id)
        REFERENCES payment (payment_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE bank_payment (
    payment_id          INT PRIMARY KEY,
    deposit_ref         VARCHAR(50)     NOT NULL,
    CONSTRAINT uq_bank_deposit_ref UNIQUE (deposit_ref),
    CONSTRAINT fk_bank_payment FOREIGN KEY (payment_id)
        REFERENCES payment (payment_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- 4. CLEARANCE QUEUE
-- ============================================================================

CREATE TABLE queue_request (
    request_id          INT AUTO_INCREMENT PRIMARY KEY,
    registration_id     INT             NOT NULL,
    service_id          INT             NOT NULL,
    staff_id            INT             NULL,
    payment_id          INT             NULL,
    status              ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    requested_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_queue_request_registration FOREIGN KEY (registration_id)
        REFERENCES registration (registration_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_queue_request_service FOREIGN KEY (service_id)
        REFERENCES queue_service (service_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_queue_request_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_queue_request_payment FOREIGN KEY (payment_id)
        REFERENCES payment (payment_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE clearance_record (
    clearance_id        INT AUTO_INCREMENT PRIMARY KEY,
    request_id           INT             NOT NULL,
    staff_id             INT             NULL,
    cleared_via          ENUM('SchoolPay_Auto','Bank_Verified') NOT NULL,
    cleared_at           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes                VARCHAR(255)    NULL,
    CONSTRAINT uq_clearance_request UNIQUE (request_id),
    CONSTRAINT fk_clearance_request FOREIGN KEY (request_id)
        REFERENCES queue_request (request_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_clearance_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notification (
    notification_id      INT AUTO_INCREMENT PRIMARY KEY,
    student_reg_number   VARCHAR(20)     NOT NULL,
    message              VARCHAR(255)    NOT NULL,
    sent_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read              BOOLEAN         NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_notification_student FOREIGN KEY (student_reg_number)
        REFERENCES student (reg_number) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 5. TRIGGERS
-- ============================================================================

DELIMITER /

-- A non-resident registration must never carry an accommodation tier.
-- (A CHECK constraint can't express this in MariaDB when the same column
-- also sits in a composite UNIQUE key, so it is enforced here instead.)
CREATE TRIGGER trg_registration_tier_consistency
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
    IF NEW.is_resident = FALSE AND NEW.accommodation_tier_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A non-resident registration cannot have an accommodation_tier_id';
    END IF;
END /

CREATE TRIGGER trg_registration_tier_consistency_upd
BEFORE UPDATE ON registration
FOR EACH ROW
BEGIN
    IF NEW.is_resident = FALSE AND NEW.accommodation_tier_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A non-resident registration cannot have an accommodation_tier_id';
    END IF;
END /

-- Keep invoice.amount_paid as a true running total, regardless of which
-- code path inserted the payment.
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    UPDATE invoice
       SET amount_paid = amount_paid + NEW.amount
     WHERE invoice_id = NEW.invoice_id;
END /

-- A SchoolPayPayment row must always match a parent Payment whose
-- payment_method is actually 'SchoolPay'.
CREATE TRIGGER trg_schoolpay_payment_consistency
BEFORE INSERT ON schoolpay_payment
FOR EACH ROW
BEGIN
    DECLARE v_method VARCHAR(20);
    SELECT payment_method INTO v_method FROM payment WHERE payment_id = NEW.payment_id;
    IF v_method IS NULL OR v_method <> 'SchoolPay' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'schoolpay_payment.payment_id must reference a payment with payment_method = SchoolPay';
    END IF;
END /

-- A BankPayment row must always match a parent Payment whose
-- payment_method is actually 'Bank'.
CREATE TRIGGER trg_bank_payment_consistency
BEFORE INSERT ON bank_payment
FOR EACH ROW
BEGIN
    DECLARE v_method VARCHAR(20);
    SELECT payment_method INTO v_method FROM payment WHERE payment_id = NEW.payment_id;
    IF v_method IS NULL OR v_method <> 'Bank' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'bank_payment.payment_id must reference a payment with payment_method = Bank';
    END IF;
END /

-- Fire a notification the moment a clearance is granted.
CREATE TRIGGER trg_clearance_record_notify
AFTER INSERT ON clearance_record
FOR EACH ROW
BEGIN
    INSERT INTO notification (student_reg_number, message, sent_at, is_read)
    SELECT r.student_reg_number,
           CONCAT('You have been cleared (', NEW.cleared_via, ') for ', s.label, '.'),
           NOW(), FALSE
      FROM queue_request qr
      JOIN registration r ON r.registration_id = qr.registration_id
      JOIN semester s ON s.semester_id = r.semester_id
     WHERE qr.request_id = NEW.request_id;
END /

-- Fire a notification the moment a clearance request is rejected.
CREATE TRIGGER trg_queue_request_rejected_notify
AFTER UPDATE ON queue_request
FOR EACH ROW
BEGIN
    IF NEW.status = 'Rejected' AND OLD.status <> 'Rejected' THEN
        INSERT INTO notification (student_reg_number, message, sent_at, is_read)
        SELECT r.student_reg_number,
               'Your clearance request was rejected. Please check your balance and try again.',
               NOW(), FALSE
          FROM registration r
         WHERE r.registration_id = NEW.registration_id;
    END IF;
END /

DELIMITER ;

-- ============================================================================
-- 6. STORED PROCEDURES
-- ============================================================================

DELIMITER /

-- Register a student for a semester and generate their invoice in one
-- atomic step, from the Program and AccommodationTier fees.
CREATE PROCEDURE sp_register_student (
    IN p_student_reg_number    VARCHAR(20),
    IN p_semester_id           INT,
    IN p_is_resident           BOOLEAN,
    IN p_accommodation_tier_id INT
)
BEGIN
    DECLARE v_program_id      INT;
    DECLARE v_tuition_fee     DECIMAL(12,2);
    DECLARE v_other_fees      DECIMAL(12,2);
    DECLARE v_tier_fee        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_registration_id INT;

    START TRANSACTION;

    SELECT program_id INTO v_program_id FROM student WHERE reg_number = p_student_reg_number;
    SELECT tuition_fee, other_fees INTO v_tuition_fee, v_other_fees
      FROM program WHERE program_id = v_program_id;

    IF p_is_resident AND p_accommodation_tier_id IS NOT NULL THEN
        SELECT tier_fee INTO v_tier_fee FROM accommodation_tier WHERE tier_id = p_accommodation_tier_id;
    END IF;

    INSERT INTO registration (student_reg_number, semester_id, is_resident, accommodation_tier_id)
    VALUES (p_student_reg_number, p_semester_id, p_is_resident,
            IF(p_is_resident, p_accommodation_tier_id, NULL));

    SET v_registration_id = LAST_INSERT_ID();

    INSERT INTO invoice (registration_id, amount_due, amount_paid)
    VALUES (v_registration_id, v_tuition_fee + v_other_fees + v_tier_fee, 0);

    COMMIT;

    SELECT v_registration_id AS registration_id;
END /

-- Record a payment against an invoice and its SchoolPay/Bank subtype row
-- together, as one guaranteed unit.
CREATE PROCEDURE sp_record_payment (
    IN p_invoice_id         INT,
    IN p_amount             DECIMAL(12,2),
    IN p_payment_date       DATE,
    IN p_payment_method     ENUM('SchoolPay','Bank'),
    IN p_reference          VARCHAR(50)
)
BEGIN
    DECLARE v_payment_id INT;

    START TRANSACTION;

    INSERT INTO payment (invoice_id, amount, payment_date, payment_method)
    VALUES (p_invoice_id, p_amount, p_payment_date, p_payment_method);

    SET v_payment_id = LAST_INSERT_ID();

    IF p_payment_method = 'SchoolPay' THEN
        INSERT INTO schoolpay_payment (payment_id, schoolpay_transaction_ref)
        VALUES (v_payment_id, p_reference);
    ELSE
        INSERT INTO bank_payment (payment_id, deposit_ref)
        VALUES (v_payment_id, p_reference);
    END IF;

    COMMIT;

    SELECT v_payment_id AS payment_id;
END /

-- Request clearance for a registration. For a SchoolPay request, the 45%
-- threshold is evaluated immediately and hardcoded here by design. For a
-- Bank Verification request, it is left Pending for a staff member.
CREATE PROCEDURE sp_request_clearance (
    IN p_registration_id    INT,
    IN p_service_id         INT,
    IN p_payment_id         INT
)
BEGIN
    DECLARE v_service_type   ENUM('SchoolPay','Bank');
    DECLARE v_request_id     INT;
    DECLARE v_amount_due     DECIMAL(12,2);
    DECLARE v_amount_paid    DECIMAL(12,2);
    DECLARE v_percent_paid   DECIMAL(7,4);

    SELECT service_type INTO v_service_type FROM queue_service WHERE service_id = p_service_id;

    START TRANSACTION;

    INSERT INTO queue_request (registration_id, service_id, payment_id, status)
    VALUES (p_registration_id, p_service_id, p_payment_id, 'Pending');

    SET v_request_id = LAST_INSERT_ID();

    IF v_service_type = 'SchoolPay' THEN
        SELECT amount_due, amount_paid INTO v_amount_due, v_amount_paid
          FROM invoice WHERE registration_id = p_registration_id;

        SET v_percent_paid = IF(v_amount_due = 0, 1, v_amount_paid / v_amount_due);

        IF v_percent_paid >= 0.45 THEN
            UPDATE queue_request SET status = 'Approved' WHERE request_id = v_request_id;
            INSERT INTO clearance_record (request_id, staff_id, cleared_via)
            VALUES (v_request_id, NULL, 'SchoolPay_Auto');
        ELSE
            UPDATE queue_request SET status = 'Rejected' WHERE request_id = v_request_id;
        END IF;
    END IF;
    -- Bank Verification requests are left Pending for sp_resolve_bank_verification.

    COMMIT;

    SELECT v_request_id AS request_id;
END /

-- A staff member resolves a pending Bank Verification request.
CREATE PROCEDURE sp_resolve_bank_verification (
    IN p_request_id     INT,
    IN p_staff_id       INT,
    IN p_approve        BOOLEAN,
    IN p_notes          VARCHAR(255)
)
BEGIN
    START TRANSACTION;

    IF p_approve THEN
        UPDATE queue_request SET status = 'Approved', staff_id = p_staff_id
         WHERE request_id = p_request_id;

        INSERT INTO clearance_record (request_id, staff_id, cleared_via, notes)
        VALUES (p_request_id, p_staff_id, 'Bank_Verified', p_notes);
    ELSE
        UPDATE queue_request SET status = 'Rejected', staff_id = p_staff_id
         WHERE request_id = p_request_id;
    END IF;

    COMMIT;
END /

DELIMITER ;

-- ============================================================================
-- 7. VIEWS
-- ============================================================================

-- One row per registration: the student, their program, their chosen
-- accommodation (if any), their invoice progress, and whether they are
-- currently cleared.
CREATE VIEW v_student_status AS
SELECT
    s.reg_number,
    s.full_name,
    p.program_name,
    sem.label                                   AS semester,
    r.registration_id,
    r.is_resident,
    at.tier_name                                AS accommodation_tier,
    inv.amount_due,
    inv.amount_paid,
    ROUND(inv.amount_paid / NULLIF(inv.amount_due, 0) * 100, 2) AS percent_paid,
    latest_clearance.cleared_via,
    latest_clearance.cleared_at,
    CASE WHEN latest_clearance.clearance_id IS NOT NULL THEN 'Cleared' ELSE 'Not Cleared' END AS clearance_status
FROM student s
JOIN registration r        ON r.student_reg_number = s.reg_number
JOIN semester sem           ON sem.semester_id = r.semester_id
JOIN program p               ON p.program_id = s.program_id
LEFT JOIN accommodation_tier at ON at.tier_id = r.accommodation_tier_id
JOIN invoice inv             ON inv.registration_id = r.registration_id
LEFT JOIN (
    SELECT cr.*
      FROM clearance_record cr
      JOIN queue_request qr ON qr.request_id = cr.request_id
) AS latest_clearance
    ON latest_clearance.request_id IN (
        SELECT qr2.request_id FROM queue_request qr2 WHERE qr2.registration_id = r.registration_id
    );

-- Every Bank Verification request still waiting, with the deposit details
-- a teller needs to check it.
CREATE VIEW v_pending_bank_verifications AS
SELECT
    qr.request_id,
    s.reg_number,
    s.full_name,
    pay.amount,
    pay.payment_date,
    bp.deposit_ref,
    qr.requested_at
FROM queue_request qr
JOIN queue_service qs  ON qs.service_id = qr.service_id AND qs.service_type = 'Bank'
JOIN payment pay         ON pay.payment_id = qr.payment_id
JOIN bank_payment bp     ON bp.payment_id = pay.payment_id
JOIN registration r       ON r.registration_id = qr.registration_id
JOIN student s             ON s.reg_number = r.student_reg_number
WHERE qr.status = 'Pending';
