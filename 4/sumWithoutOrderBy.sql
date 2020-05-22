SELECT DISTINCT
    key1,
    key2,
    (SELECT SUM(data1) FROM t y
        WHERE x.key1 = x.key1 AND x.key2 = y.key2),
    (SELECT MIN(data2) FROM t y
        WHERE x.key1 = x.key1 AND x.key2 = y.key2)
FROM t x