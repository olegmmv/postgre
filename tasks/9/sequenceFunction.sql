CREATE OR REPLACE FUNCTION getSequence(n INT) 
RETURNS TABLE (num INT) AS $$ DECLARE i INT;
BEGIN 
    CREATE temp TABLE t(num INT);
    FOR i IN 1..n LOOP 
        INSERT INTO t VALUES (i);
    END LOOP;
    RETURN query 
    SELECT * FROM t;
    DROP TABLE t;
END;
$$ LANGUAGE plpgsql;

SELECT num FROM getSequence(10);
