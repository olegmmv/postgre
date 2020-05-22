CREATE TABLE partners(
    id serial PRIMARY KEY, 
    name text
);

CREATE TABLE goods_groups(
    id serial PRIMARY KEY, 
    name text
);

CREATE TABLE goods(
    id serial PRIMARY KEY, 
    name text, 
    id_group int REFERENCES goods_groups(id)
);

CREATE TABLE prices(
    id serial PRIMARY KEY, 
    name text
);

CREATE TABLE price_lists(
    id serial PRIMARY KEY, 
    id_price int REFERENCES prices(id),
    id_goods int REFERENCES goods(id),
    price decimal(18, 4),
    ddate date
);

CREATE TABLE group_parts(
    id serial PRIMARY KEY, 
    name text
);

CREATE TABLE ggroup_parts(
    id serial PRIMARY KEY, 
    id_ggroup_part int REFERENCES group_parts(id),
    id_goods_group int REFERENCES goods_groups(id)
);

CREATE TABLE price_ggroups(
    id serial PRIMARY KEY, 
    id_price int REFERENCES prices(id),
    id_ggroup_part int REFERENCES group_parts(id),
    id_partner int REFERENCES partners(id)
);

-- Inserting pseudo-random values
INSERT INTO partners(name)
SELECT ('Partner '||t)::text
FROM generate_series(1, 20) AS t;

INSERT INTO goods_groups(name)
SELECT ('Goods group '||t)::text
FROM generate_series(1, 10) AS t;

INSERT INTO goods(name, id_group)
SELECT ('Good '||t)::text,
    (SELECT id FROM goods_groups
        WHERE t > 0
    ORDER BY random() LIMIT 1)
FROM generate_series(1, 50) AS t;

INSERT INTO prices(name)
SELECT ('Price '||t)::text
FROM generate_series(1, 20) AS t;

INSERT INTO price_lists(id_price, id_goods, price, ddate)
SELECT
    (SELECT id FROM prices
        WHERE t > 0
    ORDER BY random() LIMIT 1),
    (SELECT id FROM goods
        WHERE t > 0
    ORDER BY random() LIMIT 1), 
    t*2.5,
    '2020-03-01'::date + t
FROM generate_series(1, 30) AS t;

INSERT INTO group_parts(name)
SELECT ('Partner goods group '||t)::text
FROM generate_series(1, 10) AS t;

INSERT INTO ggroup_parts(id_ggroup_part, id_goods_group)
SELECT
    (SELECT id FROM group_parts
    WHERE t > 0
    ORDER BY random() LIMIT 1),
    (SELECT id FROM goods_groups
    WHERE t > 0
    ORDER BY random() LIMIT 1)
FROM generate_series(1, 30) AS t;

INSERT INTO price_ggroups(id_price, id_ggroup_part, id_partner)
SELECT
    (SELECT id FROM prices
    WHERE t > 0
    ORDER BY random() LIMIT 1),
    (SELECT id FROM group_parts
    WHERE t > 0
    ORDER BY random() LIMIT 1),
    (SELECT id FROM partners
    WHERE t > 0
    ORDER BY random() LIMIT 1)
FROM generate_series(1, 30) AS t ;

-- Products with different prices for one partner
WITH tmp AS
    (SELECT tab.name,
        tab.id_goods,
        tab.ddate,
        tab.id_partner,
        count(*)
    FROM
    (SELECT DISTINCT g.name,
        plist.id_goods,
        plist.ddate,
        pgg.id_partner,
        plist.id_price
    FROM price_lists AS plist
        JOIN goods g ON g.id = plist.id_goods
        JOIN ggroup_parts ggp ON ggp.id_goods_group = g.id_group
        JOIN price_ggroups pgg ON plist.id_price = pgg.id_price
        AND pgg.id_ggroup_part = ggp.id_ggroup_part) AS tab
    GROUP BY tab.name,
        tab.id_goods,
        tab.ddate,
        tab.id_partner
    HAVING count(*) > 1)
SELECT g.name,
    plist.id_goods,
    plist.ddate,
    pgg.id_partner,
    string_agg(plist.id_price::text, ',')
FROM price_lists AS plist
    JOIN goods g ON g.id = plist.id_goods
    JOIN ggroup_parts ggp ON ggp.id_goods_group = g.id_group
    JOIN price_ggroups pgg ON plist.id_price = pgg.id_price
    AND pgg.id_ggroup_part = ggp.id_ggroup_part
WHERE plist.id_goods IN
    (SELECT id_goods FROM tmp)
AND plist.ddate IN
    (SELECT ddate FROM tmp)
AND pgg.id_partner IN
    (SELECT id_partner FROM tmp)
GROUP BY g.name,
    plist.id_goods,
    plist.ddate,
    pgg.id_partner;

-- Prices for a specific partner on a given date
WITH product AS
    (SELECT plist.id_goods,
        g.name,
        g.id_group,
        ggp.id_ggroup_part,
        plist.price,
        plist.ddate,
        plist.id_price
    FROM price_lists AS plist
        JOIN goods g ON g.id = plist.id_goods
        JOIN ggroup_parts ggp ON ggp.id_goods_group = g.id_group)
SELECT DISTINCT pr.name, pr.price
FROM price_ggroups AS pgg
    JOIN product pr ON pr.id_price = pgg.id_price
    AND pgg.id_ggroup_part = pr.id_ggroup_part
WHERE pgg.id_partner = 4
AND pr.ddate = '2020-03-04';
