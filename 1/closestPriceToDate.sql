CREATE TABLE products (
    id serial PRIMARY KEY, 
    product_id int NOT NULL,
    price int NOT NULL, 
    date_added date NOT NULL
);

INSERT INTO products(product_id, price, date_added) 
values(1, 120, '2018-06-06'),
(2, 130, '2018-07-06'),
(3, 140, '2018-02-04'),
(4, 150, '2019-06-06'),
(2, 160, '2018-10-05'),
(3, 170, '2018-12-06'),
(1, 180, '2019-01-10'),
(5, 190, '2018-12-06'),
(1, 200, '2018-10-12'),
(2, 210, '2019-02-06'),
(3, 220, '2019-03-15');

SELECT price FROM products
WHERE product_id = 2 AND date_added = (
    SELECT date_added FROM products
    WHERE date_added <= '2018-10-04' AND product_id = 2
    ORDER BY date_added DESC
    LIMIT 1
)

-- Without LIMIT
SELECT p1.price FROM products as p1 
WHERE p1.product_id = 2 AND p1.date_added <= '2018-10-04' 
AND NOT EXISTS (
    SELECT product_id, price, date_added FROM products as p2 
    WHERE p2.product_id = p1.product_id 
    AND p1.date_added < p2.date_added 
    AND p2.date_added <= '2018-10-04'
)