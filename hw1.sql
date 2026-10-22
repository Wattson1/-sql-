-- ============================================================
-- Домашнее задание к лекции «SQL. Введение»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Иван Савин
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================

SET search_path TO hh_school;


-- ============================================================
-- БЛОК А. Разминка: термины и структура (текстом)
-- ============================================================

-- ЗАДАНИЕ А1
-- 1. Категория и конкретный тип колонок:
--    vacancies.salary_from        — категория: числовой   тип: INTEGER
--    vacancies.vacancy_name       — категория: строковый   тип: TEXT
--    vacancies.published_at       — категория: дата и время   тип: TIMESTAMP
--    employers.is_accredited_it   — категория: логический   тип: BOOLEAN
--    responses.created_at         — категория: дата и время   тип: TIMESTAMP
--
-- 2. Первичные ключи таблиц:
--    areas: area_id
--    employers: employer_id
--    vacancies: vacancy_id
--    vacancy_details: vacancy_id (он одновременно является внешним ключом
--    и ссылается на vacancies.
--    responses: response_id
--
-- 3. Почему vacancy_name не может быть первичным ключом:
--    Названия вакансий могут повторяться, а первичный ключ должен быть уникальным.
--    Запрос для подтверждения числом:
SELECT vacancy_name, COUNT(*) AS count_vacancies
FROM vacancies
GROUP BY vacancy_name
HAVING COUNT(*) > 1
order by count_vacancies desc

-- Вывод:
-- vacancy_name может повторяться, а первичный ключ должен быть уникальным. Поэтому его нельзя использовать как pk.
--
-- 4. Что произойдёт при записи строки «по договорённости» в salary_from:
-- Если записать «по договорённости» в колонку salary_from, то выведет ошибку, потому что тип данных не integer.
-- Это хорошо, так как не будет ошиьбочных записей и не будет нарушена логика таблицы.

-- ============================================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================

-- ЗАДАНИЕ Б1
-- Запрос: experience
SELECT DISTINCT experience FROM vacancies;

-- Запрос: employment
SELECT DISTINCT employment FROM vacancies;

-- Запрос: professional_role
SELECT DISTINCT professional_role FROM vacancies;

-- Вывод:
-- experience: уникальных значений 3. Признаков проблем с качеством данных нет.
-- employment: уникальных значений 3. Признаков проблем с качеством данных нет.
-- professional_role: уникальных значений 3. Признаков проблем с качеством данных нет.

-- ЗАДАНИЕ Б2
-- Запрос 1: стажировки в Москве без опыта, вакансия открыта
select vacancy_id, vacancy_name, salary_from, published_at from vacancies v
where v.closed_at is null and
v.experience = 'Нет опыта' and
v.area_id in (select a.area_id from areas a where area_name = 'Москва') and
v.employment = 'Стажировка'
order by published_at desc;

-- Запрос 2: топ-10 вакансий по salary_from
select vacancy_name, professional_role, salary_from
from vacancies
order by salary_from desc nulls last
limit 10;

-- Вывод:
-- Первый запрос нашел 8 актуальных вакансий. Если убрать условие про Москву, то подходящих вакансий станет 10.

-- ЗАДАНИЕ Б3
-- Ловушка 1. NULL — выполнить и объяснить результат
SELECT count(*) FROM vacancies WHERE closed_at = NULL;
SELECT count(*) FROM vacancies WHERE closed_at IS NULL;

-- Ловушка 2. AND / OR — выполнить и объяснить результат
SELECT count(*) FROM vacancies
WHERE area_id = 1 OR area_id = 2 AND experience = 'Нет опыта';

SELECT count(*) FROM vacancies
WHERE (area_id = 1 OR area_id = 2) AND experience = 'Нет опыта';

-- Вывод:
-- Запрос 1 возвращает кол-во строк, где closed_at = null, но проверка closed_at = NULL всегда вернет NULL,
-- поэтому вернет 0 строк и count(*) вернет 0. Условие closed_at IS NULL вернет нам строчки где closed_at IS NULL
-- и count(*) посчитает их и вернет кол-во таких строк. null в колонке closed_at показывает, что вакансия еще открыта.
--
-- Запрос 2 возвращает вакансии из (области 2 и у которых не требуется опыт) или из области 1. Тут приоритетность
-- операций: сначала and потом or. Запрос с условием, где есть скобки, возвращает логически правильный результат.

-- ============================================================
-- БЛОК В. Агрегации и метрики
-- ============================================================

-- ЗАДАНИЕ В1
-- Запрос 1: счётчики (строки, зарплата указана, направления, работодатели)
select count(*),
count(salary_from),
count(distinct professional_role),
count(distinct employer_id)
from vacancies;

-- Запрос 2: доля активных вакансий (без JOIN)
select count(vacancy_id) filter (where closed_at is not null) as closed,
count(vacancy_id) filter (where closed_at is null) as opend,
round(100.0 * (count(vacancy_id) filter (where closed_at is null)) / count(vacancy_id),1) as convers_opend
from vacancies v;

-- Вывод:
-- count(*) учитывает все строки даже null значения (52). count(salary_from) учитывает только столбец salary_from и
-- не учитывает null значения (44). count(distinct professional_role) учитывает только уникальные значения
-- professional_role (5)
-- В данный момент кол-во открытых вакансий 33 и 19 закрытых вакансий, доля открытых вакансий составляет 63,5%

-- ЗАДАНИЕ В2
-- Запрос 1: направления — вакансии, работодатели, средняя зарплата
select professional_role,
count(vacancy_id) as count_vacancies,
count(distinct v.employer_id) as count_employer,
round(avg(salary_from),0) as avg_salary_from
from vacancies v
 group by professional_role
order by count_vacancies desc;

-- Запрос 2: то же, только направления с ≥ 5 открытыми вакансиями (WHERE + HAVING)
select professional_role,
count(vacancy_id) as count_vacancies,
count(distinct v.employer_id) as count_employer,
round(avg(salary_from),0) as avg_salary_from
from vacancies v
where closed_at IS NULL
group by professional_role
having count(vacancy_id) >= 5
order by count_vacancies desc;

-- Вывод:
-- Два самых больших направления это аналитик данных и разработчик, они занимают больше половины вакансий.
-- Соискатель может подумать, что туда проще устроиться, но мы не знаем сколько там кандидатов и какая конкуренция.
-- Также у нас учебная база, всего 52 вакансии, поэтому делать вывод про весь рынок нельзя.
-- where нужен чтобы сначала оставить только открытые вакансии, а having уже проверяет кол-во вакансий
-- после группировки. Если написать where count(*) >= 5, то будет ошибка, потому что count нельзя в where.
-- avg(salary_from) показывает нам среднюю стартовую зарплату по направлениям там, учитывая
-- вакансии там, где она не равна null
-- Но это не значит, что столько в среднем реально получают специалисты.

-- ============================================================
-- БЛОК Г. Соединение таблиц
-- ============================================================

-- ЗАДАНИЕ Г1
-- Запрос: топ-5 по salary_from с названием компании и городом (псевдонимы таблиц)
select v.vacancy_name, e.employer_name, a.area_name, salary_from from vacancies v
left join areas a
on v.area_id = a.area_id
left join employers e
on v.employer_id = e.employer_id
order by salary_from desc nulls last
limit 5;

-- Вывод:
-- Если убрать псевдонимы и оставить только area_id, то будет ошибка, потому что area_id существует
-- в разных таблицах и неизвестно к какой именно таблице мы обращаемся.

-- ЗАДАНИЕ Г2
-- Запрос 1: все работодатели, число вакансий и откликов (LEFT JOIN)
select e.employer_name,
count(distinct v.vacancy_id) as vacancies_on_employer,
count(distinct r.response_id) as respond_on_employer
from employers e
left join vacancies v
on e.employer_id = v.employer_id
left join responses r
on v.vacancy_id = r.vacancy_id
group by e.employer_name
order by respond_on_employer desc;

-- Запрос 2: тот же запрос с INNER JOIN
select e.employer_name,
count(distinct v.vacancy_id) as vacancies_on_employer,
count(distinct r.response_id) as respond_on_employer
from employers e
inner join vacancies v
on e.employer_id = v.employer_id
inner join responses r
on v.vacancy_id = r.vacancy_id
group by e.employer_name
order by respond_on_employer desc;

-- Вывод:
-- кол-во строк во втором запросе 11, в первом запросе 12. Потому что мы используем inner join и
-- находим только те строки, которые совпадают в обеих таблицах. Тоесть ГринЭнерго вообще не иммет
-- откликов
-- Вывод:кол-во вакансий приходится считать через count потому что после left join у нас могли
-- образоваться null значения, которые не надо учитывать, также учитываем только уникальные вакансии,
-- поэтому используем count(distinct)
-- Исчезла компания ГринЭнерго т.к. она не имеет откликов. Мы теряем информацию про компанию,
-- у которой нет откликов, и поэтому вывод про активность работодателей может быть неверным.
-- inner join используем когда нужны только совпадающие строки, а left join когда надо оставить
-- все строки из левой таблицы даже если совпадений нет.

-- ============================================================
-- БЛОК Д. Функции и финальный кейс
-- ============================================================

-- ЗАДАНИЕ Д1
-- Запрос: помесячная динамика откликов и конверсия
-- (месяц как дата, условный агрегат, nullif в знаменателе)

select date_trunc('month', created_at)::date as month,
count(response_id) as cnt_response,
count(response_id) filter ( where status = 'invited') as invited_count,
round(
        100.0 * count(response_id) filter (where status = 'invited')
        / nullif(count(response_id), 0),
        1
    ) as conversion
from responses
group by date_trunc('month', created_at)
order by month


-- Вывод:
-- Максимальная конверсия в июне (19,5) 118 откликов и 23 приглашения.
-- Кол-во откликов и приглашений достаточно большое относитлеьно других месяцев, но все равно нельзя
-- уверенно утверждать, что июнь лучший месяц, на конверсию могут влиять и другие факторы.
-- Последний месяц август, там всего 41 отклик и 3 приглашения. Этот месяц неполный, поэтому данных меньше.
-- Также не все отклики могли успеть обработать работадатели, поэтому август лучше исключить из вывода

-- Запрос, подтверждающий, что месяц август неполный
select max(created_at) as last_response,
min(created_at) as first_response
from responses
where created_at >= '2026-08-01'
  and created_at < '2026-09-01'
  
-- Вывод: мы видим, что первый отклик был 1 августа, последний 15 августа -> у нас нет статистики за весь месяц 
  
  
-- ЗАДАНИЕ Д2
-- Запрос: таблица по направлениям (вакансии, отклики, приглашения,
-- откликов на вакансию, конверсия)

select professional_role,
count(distinct v.vacancy_id) as cnt_vacancy, 
count(r.response_id) as cnt_response,
count(r.response_id) filter (where r.status = 'invited') as cnt_invited,
round(count(r.response_id) * 1.0 / nullif(count(distinct v.vacancy_id),0),1) as avg_vacincy,
round(count(r.response_id) filter (where r.status = 'invited') * 100.0 / nullif(count(r.response_id),0),1) as conversion
from vacancies as v
left join responses as r
on v.vacancy_id = r.vacancy_id
group by professional_role

-- Письменные ответы:
-- 1. Нет, не совпадает. Больше всего вакансий у аналитиков данных (16),
-- но самая высокая конверсия у тестировщиков (35,9%).
--
-- 2. Я бы выбрал направление тестировщик, потому что там самая
-- высокая конверсия (35,9%) и всего 5,6 откликов на одну вакансию.(конкуренция меньше)
--
-- 3. Оговорка к выводу:
-- Нельзя точно сказать, что тестировщиком легче устроиться,
-- потому что мы не учитываем опыт кандидатов и другие факторы. Также выборка небольшая
--


-- ============================================================
-- БЛОК Е. Со звёздочкой
-- ============================================================

-- ЗАДАНИЕ Е1
-- Исходный запрос (выполнить и посмотреть результат):
SELECT v.professional_role,
count(*) AS vacancies,
sum(v.salary_from) AS total_salary,
count(r.response_id) / count(*) AS responses_per_vacancy
FROM vacancies v
JOIN responses r ON v.vacancy_id = r.vacancy_id
WHERE v.closed_at = NULL
GROUP BY 1;
--JOIN responses r ON v.vacancy_id = r.vacancy_id 
--WHERE v.closed_at is null

--
-- Ошибки (минимум четыре):
-- 1. v.closed_at = NULL - неверная проверка на актуальность вакансии (всегда вернет null)
-- 2. count(*) AS vacancies - неверный подсчет кол-во вакансий, счиатает дубликаты после join 
-- 3. sum(v.salary_from) AS total_salary - неверный подсет суммы зарплаты, считает дубликаты после join 
-- 4. count(r.response_id) / count(*) AS responses_per_vacancy - неверный подсчет кол-во вакансий, счиатает дубликаты после join 
-- 5. JOIN responses -  неверный join, сохранаяет только вакансии, на которые есть отклики

-- Исправленный запрос:

with salary_role as (select v.professional_role,
round(avg(v.salary_from),0) as avg_salary
from vacancies as v
WHERE v.closed_at is null
group by v.professional_role)


 select 
 main.professional_role,
 main.vacancies,
 sr.avg_salary,
 main.responses_per_vacancy
 from (SELECT v.professional_role, -- должность
 count(distinct v.vacancy_id) AS vacancies, -- кол-во вакансий на эту должность
-- sum(v.salary_from) AS total_salary,
 round(count(r.response_id) * 1.0 /  nullif(count(distinct v.vacancy_id),0),1) AS responses_per_vacancy
 FROM vacancies v
 LEFT JOIN responses r ON v.vacancy_id = r.vacancy_id -- join (остаются все вакансии)
 WHERE v.closed_at is null -- только открытые вакансии
 GROUP BY 1) as main
 left join salary_role as sr
 on main.professional_role = sr.professional_role
 
 -- Исправил запрос, добавил cte, в которой отдельно считается средняя нижняя граница стартовых зарплат по должности
 -- и после этого добавляю к осноному запросу, в котором считаю кол-во вакансий на эту должность и другие метрики.

-- Какие два правила из лекции защитили бы от этих ошибок при написании запроса:
-- 1. Делать проверку с null через оператор is
-- 2. Правильно выбирать join и всегда проверять возможность появления новых строк при join
