CREATE OR REPLACE FUNCTION predict(d1 date, d2 date, window_size int) 
RETURNS TABLE (region int, ddate date, ssum int, prediction double precision) AS $$
DECLARE
    curs CURSOR FOR SELECT city.region, recept.ddate, SUM(goods.weight * recgoods.volume)
        FROM city
            JOIN client ON client.city = city.id
            JOIN recept ON recept.client = client.id
            JOIN recgoods ON recgoods.subid = recept.id
            JOIN goods ON goods.id = recgoods.goods
        WHERE recept.ddate BETWEEN '2019-01-02' AND '2019-12-31'
        GROUP BY city.region, recept.ddate ;
    N int := (select count(1)
        FROM city
            JOIN client ON client.city = city.id
            JOIN recept ON recept.client = client.id
            JOIN recgoods ON recgoods.subid = recept.id
            JOIN goods ON goods.id = recgoods.goods
        WHERE recept.ddate BETWEEN '2019-01-02' AND '2019-12-31'
        GROUP BY city.region, recept.ddate);
    pred double precision;
    cnt int;
    rg int;
    dd date;
    ss int;


BEGIN
    CREATE TEMP TABLE t (
        region int,
        ddate date,
        ssum int,
        prediction double precision
    );

    IF N < window_size THEN
        INSERT INTO t VALUES (Null, Null, Null, Null);
        RETURN query SELECT * FROM t;
        DROP TABLE t;
    END IF;

    OPEN curs;
    cnt = 0;
    
    LOOP
        FETCH curs INTO rg, dd, ss;
        EXIT WHEN NOT FOUND;
        IF cnt < window_size THEN
            INSERT INTO t VALUES (rg, dd, ss, Null);
        ELSE
            pred = (SELECT sum(t.ssum)
                    FROM (SELECT ssum, row_number() OVER () AS row_n FROM t) AS t
                    WHERE row_n >= cnt - window_size AND row_n <= cnt) / window_size;
            INSERT INTO t VALUES (rg, dd, ss, prediction);
        END IF;
        cnt = cnt + 1;
    END LOOP;

    CLOSE curs;
    RETURN query SELECT * FROM t;
    DROP TABLE t;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM predict('2019-01-02', '2019-12-31', 2);