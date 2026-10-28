-- ============================================================
-- Домашнее задание к лекции «Продвинутый SQL»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Иван Савин
-- ============================================================

SET search_path TO hh_school;

-- ============================================================
-- Блок А. Качество и подготовка данных
-- ============================================================

-- №1
-- Проверка таблицы calls

select count(*),
count(*) filter (where call_id is null) as call_id_null,
count(*) filter (where response_id is null) as response_id_null,
count(*) filter (where employer_id is null) as employer_id_null,
count(*) filter (where applicant_id is null) as applicant_id_null,
count(*) filter (where vacancy_id is null) as vacancy_id_null,
count(*) filter (where caller_role is null) as caller_role_null,
count(*) filter (where call_duration is null) as call_duration_null,
count(*) filter (where status is null) as status_null,
count(*) filter (where call_at is null) as call_at_null,
count(*) filter (where call_tags is null) as call_tags_null from calls
-- Проверка всех null значений во всех столбцах
-- response_id - 8 null - мы не знаем id отлика по вакансии
-- call_duration - 70 (69 - unsuccessful, 1 - error) null (звонок не состоялся, длительность неизвестна)

select * from calls
where response_id  is null
-- Выведены все строки, где неизвестен id отклика. response_id = null означает, что мы не можем связать звонок с конкретным
-- отлкиком и не можем посчитать значения, которые сранивают к примеру среднее время от отклика до звонка или долю откликов,
-- после которых позвонили. Для отслаьных показателей, мы можем использовать эти звонки.

select status, count(*) from calls
where call_duration is null
group by status
-- call_duration - 70 (69 - unsuccessful, 1 - error). call_duration = null  означает, что звонок не состоялся или произошла
-- ошибка, длительность неизвестна.
-- Звонков с call_duration = null и status = successful нет.

select count(*) from calls
where call_duration < 0
-- Звонков с call_duration < 0 нет. (Нет звонков которые дилились < 0 секунд)

select count(*) from calls
where call_duration = 0 and status = 'successful'
-- Звонков со status successful и длительностью 0 секунд нет - логика не нарушается

select count(*) from calls
where call_duration > 0 and status = 'unsuccessful'
-- Звонков со status unsuccessful и длительностью > 0 секнуд нет - логика не нарушается

select count(*) from calls
where status = 'unsuccessful' and call_duration is not null
-- Звонков unsuccessful и call_duration is not null нет - логика не нарушается

select count(*) from calls as c
left join responses as r
on c.response_id  = r.response_id 
where r.response_id is null
and c.response_id is not null
-- Звонки, которые имеют response_id не null привязаны к отликам отсутсвуют

select count(*) from calls as c
left join employers e 
on c.employer_id = e.employer_id 
where e.employer_id is null
-- Все звонки привязаны к работадателям

select count(*) from calls as c
left join vacancies v 
on c.vacancy_id  = v.vacancy_id  
where v.vacancy_id  is null
-- Все звонки привязаны к вакансиям


select count(*) from calls c
left join vacancies v
on c.vacancy_id = v.vacancy_id 
where c.employer_id != v.employer_id 
-- Работадатель и вакансии совпадают в звонках


select count(*) from calls c
left join responses r 
on c.response_id = r.response_id
where c.vacancy_id != r.vacancy_id 
-- Вакансии совпадают в таблице звонков и вакансий, несовпадений нет.

select count(*) from calls c
join responses r 
on c.response_id  =r.response_id 
where c.call_at < r.created_at 
-- Звонков до отклика на вакансию не было (звонки с response_id is null в эту проверку не входят)

select c.call_id,
    c.response_id,
    c.vacancy_id,
    c.call_at,
    v.published_at
from calls c
join vacancies v 
on c.vacancy_id = v.vacancy_id 
where c.call_at < v.published_at 
-- 3 звонка были зафиксированы до публикации вакансии, это нарушение логики. Не учитываем эти звонки для расчета времени
-- от публикации вакансии до звонка, для остальных расчетов проверяем другие данные.

select count(*) from calls c
where status = 'error' and c.call_duration is not null
-- Нет звонков у которых статус error, но длительность известна.


select c.response_id,
count(distinct c.applicant_id ) as appl_count
from calls c 
where c.response_id is not null
group by c.response_id
having count(distinct applicant_id) > 1
-- Нет звонков по одному отклику от разных людей. Согласованность кандидатов и звонков не нарушается.

select
    call_id,
    response_id,
    call_duration
from calls
where status = 'successful'
order by call_duration desc, call_id
limit 10
-- Максимальная длительность звонка не аномальна, ее можно учитывать при подсчете разных метрик

select 
round(avg(call_duration),2) as avg_duration,
percentile_cont(0.5) within group (order by call_duration) as median_duration,
percentile_cont(0.99) within group (order by call_duration) as p99_duration
from calls
where status = 'successful'
and call_duration > 0
-- Посчитали среднюю длительность - 467.28
-- медиану длительности - 438
-- 99-й перцентиль длительности - 890.4

select count(*) as calls_above_p99
from calls c 
where status = 'successful' and call_duration > 890.4
-- Кол-во звонков выше 99-го перцентиля - 2

select c.call_id,
c.response_id,
c.applicant_id,
c.call_duration 
from calls c 
where status = 'successful' and call_duration > 890.4
-- Информация по самым долгим звонкам 892 и 899 секунд 

select round(avg(call_duration),2) as avg_durat_above_p99
from calls c
where status = 'successful' and c.call_duration > 0 and c.call_duration <= 890.4

-- средняя длительность после исключения значений выше 99-го перцентиля = 462,49
-- Выше p99 находятся 2 звонка длительностью 892 и 899 секунд.
-- Считаю их допустимыми длинными разговорами:
-- сама длительность не даёт оснований признать записи ошибочными.
-- Средняя длительность всех успешных звонков — 467.28 секунды.
-- После исключения значений выше p99 — 462.49 секунды.
-- Для описания типичной длительности использую медиану.


-- Проверка таблицы messages

select
    count(*) as total_messages,
    count(*) filter (where message_id is null) as message_id_null,
    count(*) filter (where response_id is null) as response_id_null,
    count(*) filter (where vacancy_id is null) as vacancy_id_null,
    count(*) filter (where employer_id is null) as employer_id_null,
    count(*) filter (where applicant_id is null) as applicant_id_null,
    count(*) filter (where sent_at is null) as sent_at_null,
    count(*) filter (where sender_role is null) as sender_role_null,
    count(*) filter (where message_text is null) as message_text_null,
    count(*) filter (where message_meta is null) as message_meta_null
from messages
-- Нет значени null ни в одном столбце

select count(*)as empty_text from messages m 
where trim(m.message_text) = ''
-- Нет пустых сообщений или сообщений только из пробелов

select count(*) from messages m 
left join responses r 
on m.response_id =r.response_id 
where r.response_id is null
-- Для каждого сообщения найден отклик

select count(*) as vacancy_mis
from messages m
join responses r
    on m.response_id = r.response_id
where m.vacancy_id != r.vacancy_id
-- Для каждого сообщения вакансии совпадают. Несовпадений не обнаружено

select count(*) as employer_mis
from messages m
join vacancies v
    on m.vacancy_id = v.vacancy_id
where m.employer_id != v.employer_id
-- Работодатель сообщения совпадает с работодателем вакансии

select count(*) as messages_before_response
from messages m
join responses r
    on m.response_id = r.response_id
where m.sent_at < r.created_at
-- Нет сообщений, отправленных раньше создания связанного отклика,

select m.response_id,
    count(distinct m.applicant_id) as applicant_count
from messages m
group by m.response_id
having count(distinct m.applicant_id) > 1
-- В сообщениях по одному отклику разные applicant_id не обнаружены

select count(distinct m.message_id) as applicant_mismatch
from messages m
join calls c
    on m.response_id = c.response_id
where m.applicant_id != c.applicant_id
-- Для откликов, представленных и в messages, и в calls,
-- несовпадений applicant_id между сообщениями и звонками нет.

select
    jsonb_typeof(message_meta) as meta_type,
    count(*) as message_count
from messages
group by jsonb_typeof(message_meta)
-- У всех 2862 сообщений message_meta имеет тип object

select
    count(*) filter (
        where not (message_meta ? 'channel')
    ) as channel_missing,
    count(*) filter (
        where not (message_meta ? 'is_read')
    ) as is_read_missing,
    count(*) filter (
        where not (message_meta ? 'attachments')
    ) as attachments_missing
from messages
-- Во всех сообщениях message_meta содержит ключи: channel, is_read и attachments

-- ============================================================
-- Блок Б. История коммуникаций
-- ============================================================

-- №2

with prepared_calls as (
select  
c.response_id,
c.employer_id,
c.call_id as event_id,
c.call_at as event_at,
'call' as event_type
from calls c
join responses r 
on c.response_id  = r.response_id 
where caller_role = 'employer' and 
c.call_at >= r.created_at 
and c.call_at < r.created_at + interval '7 days'
),
prepared_messages as (
select
m.response_id,
m.employer_id,
m.message_id as event_id,
m.sent_at as event_at,
'message' as event_type
from 
messages m
join responses r
on m.response_id  = r.response_id 
where sender_role = 'employer' and 
m.sent_at >= r.created_at and m.sent_at < r.created_at + interval '7 days'
),
communication as (
select * from prepared_calls
union all
select * from prepared_messages
)

select 
count(*) as count_events,
count(distinct response_id) as response_uniq,
count(*) filter (where event_type = 'call') as count_calls,
count(*) filter (where event_type = 'message') as count_messages
from communication

-- Вывод: получены 4 числа:
-- Кол-во событий: 1096
-- Кол-во откликов с комуникацией: 382
-- Кол-во звонков: 108
-- Кол-во сообщений: 988

--№3

with prepared_calls as (
select  
c.response_id,
c.employer_id,
c.call_id as event_id,
c.call_at as event_at,
'call' as event_type
from calls c
join responses r 
on c.response_id  = r.response_id 
where caller_role = 'employer' and 
c.call_at >= r.created_at 
and c.call_at < r.created_at + interval '7 days'
),
prepared_messages as (
select
m.response_id,
m.employer_id,
m.message_id as event_id,
m.sent_at as event_at,
'message' as event_type
from 
messages m
join responses r
on m.response_id  = r.response_id 
where sender_role = 'employer' and 
m.sent_at >= r.created_at and m.sent_at < r.created_at + interval '7 days'
),
communication as (
select * from prepared_calls
union all
select * from prepared_messages
),
event_history as (select *,
row_number() over (partition by response_id order by event_at, event_type, event_id) as event_number,
lag(event_at) over (partition by response_id order by event_at, event_type, event_id) as lag_event_time,
lead(event_type) over (partition by response_id order by event_at, event_type, event_id) as lead_event_type,
count(event_id) over (partition by response_id order by event_at, event_type, event_id) as count_event,
first_value(event_type) over (partition by response_id order by event_at, event_type, event_id
rows between unbounded preceding and unbounded following) as first_event_type,
last_value(event_type) over (partition by response_id order by event_at, event_type, event_id
rows between unbounded preceding and unbounded following) as last_event_type
from communication
order by response_id, event_at, event_type, event_id),
responses_smart as(
select r.response_id,
v.employer_id,
v.professional_role,
r.status,
count(e.event_id) as count_events,
count(*) filter (where e.event_type = 'call') as count_calls,
count(*) filter (where e.event_type = 'message') as count_messages,
min(e.event_at) as first_event_time,
max(e.event_type) filter(where e.event_number = 1) as type_first_event,
max(e.event_type)filter(where e.event_number = 2) as type_second_event,
max(e.last_event_type) as type_last_event,
extract(epoch from (min(e.event_at) - r.created_at)) / 3600 as hours_to_first_event,
round(max(extract(epoch from (e.event_at - e.lag_event_time)) / 3600),2) as max_gap_hours
from responses r
left join vacancies v 
on r.vacancy_id = v.vacancy_id 
left join event_history e
on r.response_id  = e.response_id
group by r.response_id, v.employer_id, v.professional_role ,r.status)

select
    count(*) as total_responses,
    count(*) filter (
        where count_events > 0
    ) as responses_with_communication,
    count(*) filter (
        where count_events = 0
    ) as responses_without_communication,
    count(*) filter (
        where type_first_event = 'message'
    ) as first_message,
    count(*) filter (
        where type_first_event = 'call'
    ) as first_call
from responses_smart;

-- Всего откликов в витрине — 628.
-- С коммуникацией работодателя в первые 7 суток — 382.
-- Без коммуникации работодателя в первые 7 суток — 246.
-- Первой коммуникацией было сообщение — 314.
-- Первой коммуникацией был звонок — 68.

-- ============================================================
-- Блок В. Сравнение работодателей
-- ============================================================

--№4

-- используем responses_smart

select * from (select professional_role,
employer_id,
count(response_id) as total_responses,
count(response_id) filter (where count_events > 0) as responses_with_communication,
round(100.0 * count(response_id) filter (where count_events > 0) / count(response_id), 2) as communication_pct,
PERCENTILE_CONT(0.5) within group (order by hours_to_first_event) filter (where count_events > 0) as median,
PERCENTILE_CONT(0.9) within group (order by  hours_to_first_event) filter (where count_events > 0) as p90_pers,
round(100.0 * count(response_id) filter (where status = 'invited') / count(response_id),2) as invitation_pct,
dense_rank() over (partition by professional_role order by 100.0 * count(response_id)
filter (where count_events > 0) / count(response_id) desc, PERCENTILE_CONT(0.5) within group (order by hours_to_first_event)
filter (where count_events > 0) asc nulls last) as employer_rank
from responses_smart
group by professional_role, employer_id
having count(response_id) >= 8) as ranke
where ranke.employer_rank <= 2
order by professional_role, employer_rank, employer_id

-- Рейтинг работодателей внутри направления:
-- Дата-инженер: 1-е место — 106; 2-е место — 101.
-- Аналитик данных: 1-е место — 109; 2-е место — 103.
-- Разработчик: 1-е место — 112; 2-е место — 104.
-- Тестировщик: 1-е место — 107; 2-е место — 108.
-- Продуктовый аналитик: 1-е место — 103; 2-е место — 102

-- №5
with message_7_days as (
select 
m.message_id,
m.response_id,
m.employer_id,
m.sent_at,
m.sender_role
from messages as m
join responses as r
on m.response_id = r.response_id
where m.sent_at >= r.created_at and m.sent_at < r.created_at + interval '7 days'),

message_history as (
select *,
lag(sender_role) over (partition by response_id order by sent_at, message_id) as previous_sender_role,
lag(sent_at) over (partition by response_id order by sent_at, message_id) as previous_sent_at
from message_7_days ),

employer_replies as (
select *,
extract(epoch from (sent_at - previous_sent_at)) / 3600 as response_hours
from message_history
where sender_role = 'employer'
and previous_sender_role = 'applicant'
order by response_id, sent_at, message_id)

select employer_id,
count(*) as reply_count,
avg(response_hours) as avg_response_hours,
PERCENTILE_CONT(0.5) within group (order by response_hours) as median_response_hours,
PERCENTILE_CONT(0.9) within group (order by response_hours) as p90_response_hours
from employer_replies
group by employer_id
order by median_response_hours asc

-- Общее количество измеренных ответов работодателей — 749.(11 работадателей)
-- Работодатель с минимальной медианой времени ответа — 107 при среднем 9.37 - есть более длительные ответы.
-- Минимальная медиана — 3.9333 часа (3 часа 56 минут).

-- ============================================================
-- Блок Г. Сложные типы данных
-- ============================================================

-- №6.1
select
    count(*) filter (
        where 'screening' = any(calls.call_tags)
    ) as screening,
    count(*) filter (
        where 'interview' = any(calls.call_tags)
    ) as interview,
    count(*) filter (
        where 'follow_up' = any(calls.call_tags)
    ) as follow_up,
    count(*) filter (
        where 'details' = any(calls.call_tags)
    ) as details,
    count(*) filter (where call_tags && array['screening', 'interview', 'follow_up', 'details']) as valid_calls_tag,
    round(avg(cardinality(calls.call_tags)), 2) AS avg_tags
from calls
join responses
on calls.response_id = responses.response_id
where (caller_role = 'employer'
	and call_at >= responses.created_at
	and call_at < responses.created_at + interval '7 days') 
	and ((calls.status = 'successful'
		and 'connected' = any(call_tags)
        and 'no_answer' != all(call_tags)
        and 'technical_error' != all(call_tags))
    or
    (calls.status = 'unsuccessful'
        and 'no_answer' = any(call_tags)
        and 'connected' != all(call_tags)
        and 'technical_error' != all(call_tags))
    or
    (calls.status = 'error'
        and 'technical_error' = any(call_tags)
        and 'connected' != all(call_tags)
        and 'no_answer' != all(call_tags)))

-- screening — 25 звонков.
-- interview — 31 звонок.
-- follow_up — 29 звонков.
-- details — 23 звонка.
-- Валидных звонков хотя бы с одним бизнес-тегом — 108.
-- Среднее количество всех тегов на валидный звонок — 4.

-- №6.2
with parsing as(
select
    message_meta ->> 'channel' as channel,
    (message_meta ->> 'is_read')::boolean as is_read,
    message_meta -> 'attachments' as attachments
from messages m
join responses r
on m.response_id = r.response_id
where m.sender_role = 'employer'
  and m.sent_at >= r.created_at
  and m.sent_at < r.created_at + INTERVAL '7 days'
)

select 
channel,
count(*) as total_messages,
count(*) filter (where is_read is not null) as known_read_messages,
count(*) filter (where is_read = false) as no_read_messages,
round(100.0 * (count(*) filter (where is_read = false)) / nullif(count(*) filter (where is_read is not null),0),2) as procent_no_read_messages,
count(*) filter (where jsonb_array_length(attachments) > 0) as messages_with_attachments,
round(100.0 * (count(*) filter (where jsonb_array_length(attachments) > 0))/
(count(*)),2) as procent_messages_with_attachments
from parsing
group by channel

-- web: 628 сообщений, is_read известен у 628,
-- непрочитанных 52 (8.28%),
-- с вложениями 25 (3.98%).
-- mobile_app: 360 сообщений, is_read известен у 360,
-- непрочитанных 36 (10.00%),
-- с вложениями 14 (3.89%).
-- Всего: 988 сообщений.
-- Сообщений с неизвестным is_read нет.
-- Сообщений без указанного канала в результате нет.

-- ============================================================
-- Блок Д. Самостоятельное исследование
-- ============================================================

-- №7

-- Гипотеза 1:
-- По откликам, завершившимся приглашением, работодатели начинают коммуникацию быстрее, чем по остальным откликам.

-- Гипотеза 2:
-- По откликам, завершившимся приглашением, работодатели общаются интенсивнее:
-- отправляют больше сообщений и совершают больше звонков на один отклик.


with first_contact as (
select
r.response_id,
r.status,
min(least(m.sent_at, c.call_at) - r.created_at) AS first_contact_time
from responses r
left join messages m
    on r.response_id = m.response_id
    and m.sender_role = 'employer'
    and m.sent_at >= r.created_at

left join calls c
    on r.response_id = c.response_id
    and c.caller_role = 'employer'
    and c.call_at >= r.created_at
group by r.response_id, r.status)


select
    case
        when status = 'invited' then 'invited'
        else 'other'
    end as response_group,
    count(*) as responses_count,
    count(first_contact_time) as contacted_responses,
    round(
        avg(extract(epoch from first_contact_time) / 3600),
        2
    ) as avg_first_contact_hours

from first_contact
group by response_group

-- Гипотеза 1 не подтверждается.
-- Среднее время первого контакта:
-- invited — 142.95 часа (73 из 92 откликов);
-- other — 127.48 часа (420 из 536 откликов).
-- По приглашённым откликам первый контакт
-- происходил в среднем на 15.47 часа позже.


with msg as (
select
response_id,
count(*) as messages_count
from messages
where sender_role = 'employer'
group by response_id
),

cl as (
select
response_id,
count(*) as calls_count
from calls
where caller_role = 'employer'
group by response_id
)
select
case
when r.status = 'invited' then 'invited'
else 'other'
end as response_group,
count(*) as responses_count,
round(avg(coalesce(msg.messages_count, 0)), 2)as avg_messages,
round(avg(coalesce(cl.calls_count, 0)), 2)as avg_calls
from responses r
left join msg
on r.response_id = msg.response_id
left join cl
on r.response_id = cl.response_id
group by response_group
    
-- Гипотеза 2 не подтверждается полностью.
-- invited: 92 отклика, 2.22 сообщения и 0.27 звонка на отклик.
-- other: 536 откликов, 2.29 сообщения и 0.25 звонка на отклик.
-- По приглашённым откликам сообщений немного меньше, а звонков немного больше.
-- Убедительного увеличения интенсивности общения не выявлено.

with successful_calls as (
select distinct response_id
from calls
where caller_role = 'employer'
and status = 'successful'
and response_id is not null)
select
case
when r.status = 'invited' then 'invited'
else 'other'
end as response_group,
count(*) as responses_count,
count(sc.response_id) as successful_call_responses,
round(
100.0 * count(sc.response_id) / count(*), 2) as successful_call_pct
from responses r
left join successful_calls sc
on r.response_id = sc.response_id
group by response_group

-- Доля откликов с хотя бы одним успешным звонком работодателя.
-- invited: 18 из 92 откликов (19.57%)
-- other: 94 из 536 откликов (17.54%)
-- Разница составляет 2.03 процентного пункта.
-- У приглашённых откликов доля немного выше,
-- однако различие само по себе не доказывает
-- связь успешного звонка с приглашением.

-- Анализ показывает связь характеристик коммуникации
-- с итоговым статусом отклика, но не доказывает
-- причинно-следственную зависимость.
-- Также учитываются коммуникации после отклика,
-- в том числе потенциально после приглашения.

-- №8

-- №8. Итог исследования

-- Всего мы рассмотрели 628 откликов, из них по 382 (60.8%) работодатели связались с кандидатами в первые 7 дней,
-- а по 246 откликам коммуникации не было.
-- Чаще всего работодатели начинали общение с сообщения (314 случаев), со звонка (68 случаев).
-- Всего за первые 7 дней работодатели отправили 988 сообщений и совершили 108 звонков -> 
-- переписку они используют чаще.
-- Не все работодатели общаются одинаково: у работодателя 107 медианное время ответа составило
-- 3.93 часа, а среднее — 9.37 часа, то есть некоторые ответы занимали заметно больше времени.
-- в направлении «Разработчик» первое место по доле откликов с коммуникацией и скорости первого контакта
-- занял работодатель 112, а второе — 104.
-- Также мы выяснили, что доля непрочитанных сообщений в web составляет 8.28%, а в mobile_app — 10% -> большой
-- разницы между каналами нет.
-- По откликам с приглашением первый контакт происходил в среднем позже, чем по остальным: 142.95 часа против 127.48 часа.
-- При этом количество сообщений и звонков почти не отличается, но доля откликов с успешным
-- звонком немного выше у приглашённых — 19.57% против 17.54%.
-- Однако по этим данным нельзя утверждать, что какие-то действия работодателя напрямую влияют на приглашение,
-- тем более что часть общения могла происходить уже после него.
-- В дальнейшем было бы интересно узнать, как время первого контакта и количество сообщений до приглашения связаны
-- с результатом отклика, для этого нужны точные даты изменения статусов.

