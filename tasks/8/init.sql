DROP TABLE IF EXISTS remains;
DROP TABLE IF EXISTS irlink;
create table remains(
  id int,
  subid int,
  goods int references goods(id),
  storage int references storage(id),
  ddate date, -- прихода
  volume int,
  primary key(id, subid)
);

create table irlink(
  id serial,
  i_id int references income(id),
  i_subid int,
  r_id int references recept(id),
  r_subid int,
  goods int references goods(id),
  volume int,
  primary key(id)
);

