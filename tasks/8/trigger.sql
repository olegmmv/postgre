create or replace function Updated() returns trigger as
    $$
    declare
        income_storage int;
        income_date date;
        item record;
        remain record;
        dif_value int;
        remain_value int;
        irlink_sum int;
    begin
        --находим склад и дату прихода
        select storage, ddate
        into income_storage, income_date
        from income
        where id = new.id;

        --находим тот остаток, который хотим апдейтить
        select volume
        into remain_value
        from remains
        where id = new.id and subid = new.subid;

        if(new.volume > old.volume) then
            --Если количество увеличилось
            --пересчет производить не нужно
            --просто увеличиваем остаток на складе
            dif_value = old.volume - new.volume;
            insert into remains(id, subid, goods, storage, ddate, volume)
            values (new.id, new.subid, new.goods, income_storage, income_date, dif_value)
            on conflict (id, subid) do update set volume = volume + dif_value;
        else
            --если количество уменьшилось
            --производим пересчет

            create temp table irl(
                id integer,
                i_id integer,
                i_subid integer,
                r_id integer,
                r_subid integer,
                r_date date,
                goods integer,
                volume integer);

            --Выбираем все записи связанные с текущим приходом
            --из таблицы irlink
            insert into irl(id, i_id, i_subid, r_id, r_subid, r_date, goods, volume)
            select irlink.id, i_id, i_subid, r_id, r_subid, r.ddate, goods, volume
            from  irlink
            join recept r on irlink.r_id = r.id
            where i_id = old.id and i_subid = old.subid and goods = old.goods;

            --находим сумму расходов
            --связанных с изменяемым приходом
            select sum(volume)
            into irlink_sum
            from irl;

            if (new.volume > irlink_sum or new.volume = irlink_sum) then
                --если остатка товара, с учетом изменения
                --хватает на то, чтобы закрыть текущие расходы
                --пересчет не требуется
                update remains set volume = new.volume - irlink_sum
                where id = new.id and subid = new.subid;
            else

                --В случае если остатка товара, с учетом изменения
                -- недостаточно,чтобы покрыть расходы
                --необходимо выполнить перераспределение текущих расходов
                --по другим приходам, с учетом политики lifo
                update remains set volume = 0 where id = new.id and subid = new.subid;
                dif_value = irlink_sum - new.volume;
                for item in select * from irl
                loop
                    create temp table rms (
                        id integer,
                        subid integer,
                        goods integer,
                        storage integer,
                        ddate date,
                        volume integer
                    );

                    insert into rms (id, subid,goods, storage, ddate, volume)
                    select id, subid, goods, storage, ddate, volume
                    from remains
                    where storage = income_storage
                    and goods = new.goods
                    and (ddate < item.r_date or ddate = item.r_date)
                    order by ddate desc;

                    if (item.volume < dif_value) then
                        for remain in select * from rms
                        loop
                            if (item.volume < remain.volume) then
                                --Вычитаем новый расход из остатка
                                update remains set volume = (remain.volume - item.volume)
                                where id = remain.id and subid = remain.subid;
                                --Привязываем в irlink новый расход
                                update irlink set i_id = remain.id, i_subid = remain.subid
                                where irlink.id = item.id;
                                item.volume = 0;
                            else
                                --добавляем в ирлинк новую привязку
                                --к расходу из которого берем необходимое количество
                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, item.goods, remain.volume );

                                update irlink set volume = (irlink.volume - remain.volume)
                                where id = item.id;
                                item.volume = item.volume - remain.volume;

                                delete from remains where id = remain.id and subid = remain.subid;
                            end if;
                        exit when item.volume = 0;
                        end loop;
                        dif_value = dif_value - item.volume;
                    else
                        for remain in select * from rms
                        loop
                            if (dif_value < remain.volume) then
                                --Вычитаем новый расход из остатка
                                update remains set volume = (remain.volume - dif_value)
                                where id = remain.id and subid = remain.subid;

                                --Привязываем в irlink новый расход
                                update irlink set volume = (irlink.volume - dif_value)
                                where irlink.id = item.id;

                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, remain.goods, dif_value);
                                dif_value = 0;
                            else
                                --добавляем в ирлинк новую привязку
                                --к расходу из которого берем необходимое количество
                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, item.goods, remain.volume );

                                update irlink set volume = (irlink.volume - remain.volume)
                                where id = item.id;

                                dif_value = dif_value - remain.volume;
                                delete from remains where id = remain.id and subid = remain.subid;
                            end if;
                        exit when dif_value = 0;
                        end loop;
                    end if;
                --специфика datagrip - линтер не дает делать делеты без условий
                delete from rms where true;
                exit when dif_value = 0;
                end loop;
            end if;
            drop table  if exists rms;
            drop table irl;
        end if;
        delete from remains where volume = 0;
        return new;
    end
    $$ language plpgsql;

create or replace function Updating() returns trigger as
    $$
    declare
        income_storage integer;
        income_date date;
        sum integer;
    begin
        --Функция проверяет корректность процесса обновления
        --если количество товаров в приходе уменьшилось
        --и текущего количества не хватает для пересчета всех расходов
        --кидается эксепшен
        select
            recept.storage,
            recept.ddate
        into income_storage, income_date
        from recept
        where recept.id = new.id;

        sum = (
            select sum(volume)
            from remains
            where remains.goods = new.goods
            and remains.ddate < income_date
            and remains.storage = income_storage
        );

        if (new.volume <  old.volume and old.volume - new.volume  > sum) then
            raise exception 'There is not enough remains to satisfy existing recepts';
        end if;

        return new;
    end
    $$ language plpgsql;

drop trigger  if exists onUpdated on incgoods;
drop trigger if exists onUpdating on incgoods;
create trigger onUpdated
after update on incgoods for each row execute procedure Updated();

create trigger onUpdating
before update on incgoods for each row execute procedure Updating();