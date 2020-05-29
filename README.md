# Задачи по курсу "Системы обработки аналитической информации"
1. [Цена на дату](https://github.com/olegmmv/postgre/tree/master/tasks/1)

2. [Прайсы](https://github.com/olegmmv/postgre/tree/master/tasks/2)
- Давайте наполним базу псевдослучайными тестовыми данными
- Давайте проверим что прайсы партнеров не пересекаются
- Давайте напишем вывод прайсов конкретного партнера на заданную дату

3. [Запросы](https://github.com/olegmmv/postgre/tree/master/tasks/3)
- Покупки: Город, Дата, Номер документа, Название группы товара, Название товара, Объем. Выборка за второй квартал 2020 года, Объемом более 10 м3
- Продажи: Адрес, Дата, Номер документа, Название склада, Название товара, Вес, Сумма. Выборка за февраль 2020 года по региону Москва, только по товарам по которым были покупки в 2019 году.
- Выбрать 10 случайных записей из запроса с продажами.

4. [Контрольная](https://github.com/olegmmv/postgre/tree/master/tasks/4)
Переписать запрос без слов GROUP BY используя стандартные возможности SQL

5. [Вставка, изменение и удаление]](https://github.com/olegmmv/postgre/tree/master/tasks/5)
- Давайте создадим и заполним таблицу по поставкам в разрезе дней и складов:
Дата, Склад, Сумма руб., Объем м3, Число разных товаров
- Давайте заведем у Склада поле Признак активности.
Написать запрос, который установит Признак = 1, если со склада были продажи более чем на 10000 руб. за последний месяц.
- Давайте удалим из таблицы товаров все товары по которым не было продаж и поставок

6. [Посчитать остатки на складах по всем дням периода с 1 марта 2020 года по 14 марта 2020 года](https://github.com/olegmmv/postgre/tree/master/tasks/6)

7. [Прогноз продаж через хранимую процедуру](https://github.com/olegmmv/postgre/tree/master/tasks/7)

8. [Триггер](https://github.com/olegmmv/postgre/tree/master/tasks/8)

9. [Контрольная на создание последовательности](https://github.com/olegmmv/postgre/tree/master/tasks/9)

10. [Контрольная. Дерево товаров](https://github.com/olegmmv/postgre/tree/master/tasks/10)

11. [Дерево клиентов. Lateral последовательностей](https://github.com/olegmmv/postgre/tree/master/tasks/11)

12. [Оконные функции](https://github.com/olegmmv/postgre/tree/master/tasks/12)

13. [Прогноз через Python](https://github.com/olegmmv/postgre/tree/master/tasks/13)

14. [Соревнование по мерам и измерениям (в классе)](https://github.com/olegmmv/postgre/tree/master/tasks/14)

15. [Наполним транзакционную базу, заполним случайными данными, создадим хранилище, напишем ETL, пришлем мне 2 дампа и все скрипты.](https://github.com/olegmmv/postgre/tree/master/tasks/15)

16. [Создать MOLAP icCube и написать MDX](https://github.com/olegmmv/postgre/tree/master/tasks/16)
