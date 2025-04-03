BEGIN;

-- first action
UPDATE employees
SET salary = salary + 500
WHERE id = 3;

SAVEPOINT my_savepoint;

-- second action
UPDATE employees
SET salary = salary - 500
WHERE id = 4;

-- if we would like to undo deduction, then ...
ROLLBACK TO my_savepoint;

COMMIT;

select * from employees order by id asc;