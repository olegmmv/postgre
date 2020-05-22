WITH RECURSIVE tmp AS (
	SELECT g1.id, g1.name, g1.parent, g2.name parent_name
	FROM goods_groups AS g1 
        JOIN goods_groups AS g2 ON g2.id = g1.parent
	UNION ALL 
	SELECT gg.id, gg.name, tmp.parent, gp.name 
    FROM goods_groups AS gg 
		JOIN tmp ON tmp.id = gg.parent
		JOIN goods_groups AS gp ON gp.id = tmp.parent)

SELECT * FROM tmp;