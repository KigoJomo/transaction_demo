-- 1: insert a new customer
CREATE OR REPLACE PROCEDURE insert_customer(
  p_name VARCHAR(100),
  p_email VARCHAR(100),
  p_phone VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO customers(name, email, phone)
  VALUES(p_name, p_email, p_phone);
  
  COMMIT;
  RAISE NOTICE 'Customer added successfully';
END;
$$;

-- 2: Update customer email
CREATE OR REPLACE PROCEDURE update_customer_email(
  p_customer_id INT,
  p_new_email VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE customers
  SET email = p_new_email
  WHERE customer_id = p_customer_id;
  
  IF FOUND THEN
    COMMIT;
    RAISE NOTICE 'Customer email updated successfully';
  ELSE
    RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
  END IF;
END;
$$;

-- 3: delete a customer
CREATE OR REPLACE PROCEDURE delete_customer(
  p_customer_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  customer_name VARCHAR(100);
BEGIN
  SELECT name INTO customer_name FROM customers WHERE customer_id = p_customer_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
  END IF;
  
  DELETE FROM customers WHERE customer_id = p_customer_id;
  COMMIT;
  
  RAISE NOTICE 'Customer "%" deleted successfully', customer_name;
END;
$$;

-- 4: Transfer funds between accounts
CREATE OR REPLACE PROCEDURE transfer_funds(
  p_from_account INT,
  p_to_account INT,
  p_amount DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate amount
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Transfer amount must be positive';
  END IF;
  
  -- deduct from source account
  UPDATE accounts
  SET balance = balance - p_amount
  WHERE account_id = p_from_account;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Source account % not found', p_from_account;
  END IF;
  
  -- check if enough funds
  IF (SELECT balance FROM accounts WHERE account_id = p_from_account) < 0 THEN
    RAISE EXCEPTION 'Insufficient funds in account %', p_from_account;
    ROLLBACK;
    RETURN;
  END IF;
  
  -- add to destination accountt
  UPDATE accounts
  SET balance = balance + p_amount
  WHERE account_id = p_to_account;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Destination account % not found', p_to_account;
  END IF;
  
  COMMIT;
  RAISE NOTICE 'Successfully transferred $% from account % to account %', 
          p_amount, p_from_account, p_to_account;
END;
$$;

-- 5: Calculate oder total with tax
CREATE OR REPLACE PROCEDURE calculate_order_total(
  p_order_id INT,
  INOUT p_total DECIMAL(10,2),
  IN p_tax_rate DECIMAL(5,2) DEFAULT 0.05
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT SUM(price * quantity) INTO p_total
  FROM order_items
  WHERE order_id = p_order_id;
  
  IF NOT FOUND OR p_total IS NULL THEN
    p_total := 0;
    RAISE NOTICE 'No items found for order %', p_order_id;
    RETURN;
  END IF;
  
  -- Apply tax
  p_total := p_total * (1 + p_tax_rate);
  
  RAISE NOTICE 'Order % total (with %% tax): $%', 
          p_order_id, p_tax_rate * 100, p_total;
END;
$$;