-- Query 1 — Total Users and New Users

WITH UserInfo AS (

  SELECT
    user_pseudo_id,

    MAX(
      IF(event_name IN ('first_visit', 'first_open'), 1, 0)
    ) AS is_new_user

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'

  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*) AS total_users,
  SUM(is_new_user) AS new_users

FROM UserInfo;



-- Query 2 — Extract Page Location

SELECT

  TIMESTAMP_MICROS(event_timestamp) AS event_time,

  (
    SELECT value.string_value
    FROM UNNEST(event_params)
    WHERE key = 'page_location'
    LIMIT 1
  ) AS page_location

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE event_name = 'page_view'

AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'

LIMIT 50;



-- Query 3 — Item-Level Purchase Analysis

SELECT

  event_date,

  item.item_name,

  COUNT(*) AS item_rows

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e,

UNNEST(e.items) AS item

WHERE e.event_name = 'purchase'

AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'

GROUP BY event_date, item.item_name

ORDER BY item_rows DESC

LIMIT 20;



-- Query 4 — Events Seen Per Day

SELECT

  event_date,

  STRING_AGG(
    DISTINCT event_name,
    ', '
    ORDER BY event_name
  ) AS events_seen

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201203'

GROUP BY event_date

ORDER BY event_date;



-- Query 5 — Items Added to Cart

SELECT

  user_pseudo_id,

  ARRAY_AGG(item.item_name) AS items_added_to_cart

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,

UNNEST(items) AS item

WHERE event_name = 'add_to_cart'

AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'

GROUP BY user_pseudo_id

ORDER BY user_pseudo_id

LIMIT 10;



-- Query 6 — Session Cart Summary

WITH add_to_cart AS (

  SELECT

    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
      LIMIT 1
    ) AS session_id,

    items

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE event_name = 'add_to_cart'

  AND _TABLE_SUFFIX BETWEEN '20210131' AND '20210131'

)

SELECT

  user_pseudo_id,

  session_id,

  ARRAY_LENGTH(items) AS total_add_to_cart_items,

  ARRAY_AGG(
    STRUCT(
      cart_items.item_id,
      cart_items.item_name,
      cart_items.quantity,
      cart_items.price
    )
  ) AS cart_items

FROM add_to_cart,

UNNEST(items) AS cart_items

GROUP BY user_pseudo_id, session_id

LIMIT 10;