/*
Анализ ключевых метрик вовлечённости: DAU, WAU, MAU, Sticky Factor
Для оценки здоровья продукта и эффекта маркетинговых активностей
*/

-- Базовые метрики по дням, неделям, месяцам
WITH daily_metrics AS (
    SELECT
        DATE_TRUNC('day', start_session) AS day,
        COUNT(DISTINCT id_user) AS dau
    FROM skygame.game_sessions
    WHERE end_session IS NOT NULL
    GROUP BY 1
),
weekly_metrics AS (
    SELECT
        DATE_TRUNC('week', start_session) AS week,
        COUNT(DISTINCT id_user) AS wau
    FROM skygame.game_sessions
    WHERE end_session IS NOT NULL
    GROUP BY 1
),
monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', start_session) AS month,
        COUNT(DISTINCT id_user) AS mau
    FROM skygame.game_sessions
    WHERE end_session IS NOT NULL
    GROUP BY 1
),
combined AS (
    SELECT
        d.day,
        d.dau,
        w.wau,
        m.mau,
        -- Sticky Factor Weekly (еженедельная "липкость")
        ROUND(d.dau::DECIMAL / NULLIF(w.wau, 0), 3) AS sf_weekly,
        -- Sticky Factor Monthly (ежемесячная "липкость")
        ROUND(d.dau::DECIMAL / NULLIF(m.mau, 0), 3) AS sf_monthly
    FROM daily_metrics d
    LEFT JOIN weekly_metrics w 
        ON DATE_TRUNC('week', d.day) = w.week
    LEFT JOIN monthly_metrics m 
        ON DATE_TRUNC('month', d.day) = m.month
)
SELECT 
    day,
    dau,
    wau,
    mau,
    sf_weekly,
    sf_monthly,
    -- Интерпретация липкости
    CASE 
        WHEN sf_weekly >= 0.5 THEN 'Высокая вовлечённость'
        WHEN sf_weekly >= 0.3 THEN 'Средняя вовлечённость'
        ELSE 'Низкая вовлечённость'
    END AS engagement_level
FROM combined
ORDER BY day DESC;
