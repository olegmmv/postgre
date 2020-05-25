DROP FUNCTION IF EXISTS moving_average(d1 date, d2 date);

CREATE OR REPLACE FUNCTION moving_average(d1 date, d2 date)
    RETURNS table (
        region int,
        date date,
        sum int,
        prediction double precision
    )
AS
$$
DECLARE
    cursor CURSOR FOR SELECT city.region AS reg,
                             recept.ddate AS dd,
                             SUM(goods.weight * recgoods.volume) AS s
                      FROM city
                               JOIN client ON client.city = city.id
                               JOIN recept ON recept.client = client.id
                               JOIN recgoods ON recgoods.subid = recept.id
                               JOIN goods ON goods.id = recgoods.goods
                      WHERE recept.ddate >= d1
                        AND recept.ddate <= d2
                      GROUP BY city.region, recept.ddate
                      ORDER BY city.region, recept.ddate
    ;
    cnt int := 0;
    temp_cnt int := 0;
    pred double precision;
    prev_region int;
--
    region int;
    date date;
    sum int;
BEGIN
    CREATE TEMP TABLE tmp
    (
        region int,
        date date,
        sum int
    );
    CREATE TEMP TABLE to_return
    (
        region int,
        date date,
        sum int,
        prediction double precision
    );
    OPEN cursor;
    LOOP
        FETCH cursor INTO region, date, sum;
        EXIT WHEN NOT found;

        IF region != prev_region THEN
            temp_cnt := 1;
            TRUNCATE tmp;
            INSERT INTO tmp VALUES (region, date, sum);
            INSERT INTO to_return (region, date, sum, prediction)
            VALUES (region, date, sum, sum);
        ELSE
            IF temp_cnt < 2 THEN
                temp_cnt = temp_cnt + 1;
                INSERT INTO to_return (region, date, sum, prediction)
                VALUES (region, date, sum, sum);
                INSERT INTO tmp VALUES (region, date, sum);
            ELSE
                temp_cnt = temp_cnt + 1;
                INSERT INTO to_return (region, date, sum, prediction)
                VALUES (region, date, sum, (SELECT avg(tmp.sum) FROM tmp));
                DELETE FROM tmp WHERE tmp.date IN (SELECT tmp.date FROM tmp ORDER BY tmp.date ASC LIMIT 1);
                INSERT INTO tmp VALUES (region, date, sum);
            END IF;
        END IF;
        prev_region = region;
        cnt := cnt + 1;
    END LOOP;

    CLOSE cursor;
    RETURN QUERY SELECT * FROM to_return;
    DROP TABLE to_return;
    DROP TABLE tmp;
END
$$ LANGUAGE plpgsql;

SELECT *
FROM moving_average('2020-02-01', '2020-12-31');