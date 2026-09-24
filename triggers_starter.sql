-- =====================================================================
-- CSC2209 Database Programming - Triggers
-- STUDENT STARTER FILE
--
-- How to use this file:
--   * Run ONE section at a time, only when the lecturer says so.
--   * Where you see  >>> TYPE THE TRIGGER HERE <<<  type the trigger
--     together with the lecturer, run it, THEN run the tests below it.
--   * Some tests are SUPPOSED to fail. The comments tell you which.
-- =====================================================================


-- ---------------------------------------------------------------------
-- SECTION 0: Setup - run this whole section now
-- (Running it again at any time resets everything.)
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS shop_triggers;
CREATE DATABASE shop_triggers;
USE shop_triggers;

CREATE TABLE products (
    product_id  INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    price       DECIMAL(10,2) NOT NULL,
    stock_qty   INT           NOT NULL DEFAULT 0
);

CREATE TABLE orders (
    order_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_id  INT           NOT NULL,
    quantity    INT           NOT NULL,
    unit_price  DECIMAL(10,2),                 -- filled in by a trigger
    order_date  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE price_audit (
    audit_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_id  INT           NOT NULL,
    old_price   DECIMAL(10,2) NOT NULL,
    new_price   DECIMAL(10,2) NOT NULL,
    changed_by  VARCHAR(100)  NOT NULL,
    changed_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price, stock_qty) VALUES
    ('Exercise Book',          2500.00, 100),
    ('Ballpoint Pen',           500.00, 200),
    ('Scientific Calculator', 45000.00,  10);

SELECT * FROM products;   -- you should see 3 products


-- ---------------------------------------------------------------------
-- DEMO 1: BEFORE INSERT on orders
-- Real life: your MoMo statement still shows what you paid for a bundle
--            last month, even if the bundle price has changed.
-- Goal: an order automatically records the product's current price.
-- Trigger name: trg_orders_before_insert
-- ---------------------------------------------------------------------

-- >>> TYPE THE TRIGGER HERE <<<



-- Tests
INSERT INTO orders (product_id, quantity) VALUES (1, 5);
SELECT * FROM orders;     -- unit_price should be 2500.00


-- ---------------------------------------------------------------------
-- DEMO 2: AFTER INSERT on orders
-- Real life: the moment you send money, your balance goes down.
-- Goal: placing an order reduces the product's stock.
-- Trigger name: trg_orders_after_insert
-- ---------------------------------------------------------------------

-- >>> TYPE THE TRIGGER HERE <<<



-- Tests
SELECT * FROM products WHERE product_id = 2;      -- stock = 200
INSERT INTO orders (product_id, quantity) VALUES (2, 20);
SELECT * FROM products WHERE product_id = 2;      -- stock = 180
-- Question: why is product 1's stock still 100?


-- ---------------------------------------------------------------------
-- DEMO 3: AFTER UPDATE on products
-- Real life: your MoMo statement records every change to your balance.
-- Goal: record every price change in price_audit.
-- Trigger name: trg_products_after_update
-- ---------------------------------------------------------------------

-- >>> TYPE THE TRIGGER HERE <<<



-- Tests
UPDATE products SET price = 3000.00 WHERE product_id = 1;   -- logged
UPDATE products SET stock_qty = 150 WHERE product_id = 1;   -- NOT logged
SELECT * FROM price_audit;                                  -- 1 row only


-- ---------------------------------------------------------------------
-- DEMO 4: Validation with SIGNAL
-- Real life: "Insufficient balance" - the send is refused, nothing leaves.
-- Goal: reject orders with quantity <= 0, an unknown product,
--       or not enough stock.
-- We will DROP trg_orders_before_insert and create it again.
-- ---------------------------------------------------------------------

-- >>> TYPE THE DROP + NEW TRIGGER HERE <<<



-- Tests: the first THREE should FAIL with our own error messages
INSERT INTO orders (product_id, quantity) VALUES (3, 0);    -- FAILS
INSERT INTO orders (product_id, quantity) VALUES (99, 1);   -- FAILS
INSERT INTO orders (product_id, quantity) VALUES (3, 50);   -- FAILS
INSERT INTO orders (product_id, quantity) VALUES (3, 2);    -- succeeds

SELECT * FROM orders;                         -- no rows from the failed inserts
SELECT * FROM products WHERE product_id = 3;  -- stock = 8


-- ---------------------------------------------------------------------
-- DEMO 5: AFTER DELETE on orders
-- Real life: a reversed transaction puts the money back.
-- Goal: cancelling (deleting) an order puts the stock back.
-- Trigger name: trg_orders_after_delete
-- ---------------------------------------------------------------------

-- >>> TYPE THE TRIGGER HERE <<<



-- Tests
SELECT * FROM products WHERE product_id = 3;  -- stock = 8
DELETE FROM orders WHERE product_id = 3;
SELECT * FROM products WHERE product_id = 3;  -- stock = 10


-- ---------------------------------------------------------------------
-- SECTION 6: Looking at your triggers
-- ---------------------------------------------------------------------
SHOW TRIGGERS;                     -- tip: in the MySQL CLI use  SHOW TRIGGERS\G
SHOW TRIGGERS LIKE 'orders';       -- triggers on the orders TABLE
SHOW CREATE TRIGGER trg_orders_after_insert;

SELECT trigger_name, action_timing, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'shop_triggers';


-- ---------------------------------------------------------------------
-- CLASS EXERCISE
-- ---------------------------------------------------------------------

-- Exercise 1: reject a new product if price <= 0 or stock_qty < 0



-- Exercise 2: when an order's quantity is UPDATED, adjust the stock
--             by the difference (5 -> 8 means 3 more taken from stock)
