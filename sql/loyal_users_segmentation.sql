/*
Сегментация лояльных игроков через CTE
Лояльные = тратят > 1000 руб. И/ИЛИ пригласили ≥ 3 друзей с ≥ 1 регистрацией
*/

-- Игроки с суммарными тратами > 1000 руб.
WITH paying_users AS (
    SELECT
        m.id_user,
        SUM(m.cnt_buy * p.price) AS total_spent
    FROM skygame.monetary m
    JOIN skygame.log_prices p
        ON m.id_item_buy = p.id_item
        AND m.dtime_pay BETWEEN p.valid_from 
            AND COALESCE(p.valid_to, '3000-01-01')
    GROUP BY m.id_user
    HAVING SUM(m.cnt_buy * p.price) > 1000
),
-- Игроки с активными приглашениями
active_inviters AS (
    SELECT
        id_user,
        COUNT(*) AS total_invites,
        SUM(ref_reg) AS successful_invites
    FROM skygame.referral
    GROUP BY id_user
    HAVING COUNT(*) >= 3 
        AND SUM(ref_reg) >= 1
),
-- Объединённая сегментация
user_segments AS (
    SELECT
        u.id_user,
        u.reg_date,
        -- Флаги сегментов
        CASE WHEN p.id_user IS NOT NULL THEN 1 ELSE 0 END AS is_high_payer,
        CASE WHEN a.id_user IS NOT NULL THEN 1 ELSE 0 END AS is_active_inviter,
        -- Общий флаг лояльности
        CASE 
            WHEN p.id_user IS NOT NULL OR a.id_user IS NOT NULL 
            THEN 1 
            ELSE 0 
        END AS is_loyal_user
    FROM skygame.users u
    LEFT JOIN paying_users p ON u.id_user = p.id_user
    LEFT JOIN active_inviters a ON u.id_user = a.id_user
)
-- Итоговая статистика по сегментам
SELECT
    DATE_TRUNC('month', reg_date) AS cohort_month,
    COUNT(*) AS total_users,
    SUM(is_high_payer) AS high_payers,
    SUM(is_active_inviter) AS active_inviters,
    SUM(is_loyal_user) AS loyal_users,
    -- Доли от когорты
    ROUND(SUM(is_high_payer)::DECIMAL / NULLIF(COUNT(*), 0) * 100, 1) AS high_payer_percent,
    ROUND(SUM(is_loyal_user)::DECIMAL / NULLIF(COUNT(*), 0) * 100, 1) AS loyal_users_percent
FROM user_segments
GROUP BY 1
ORDER BY 1 DESC;
