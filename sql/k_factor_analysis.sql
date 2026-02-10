/*
Расчёт K-factor (показатель вирусности) мобильной игры
Показывает, насколько игра распространяется за счёт приглашений друзей
*/

WITH referral_stats AS (
    SELECT
        -- Общее количество уникальных игроков
        COUNT(DISTINCT u.id_user) AS total_players,
        -- Количество успешных регистраций по приглашениям
        SUM(COALESCE(r.ref_reg, 0)) AS successful_invites
    FROM skygame.users u
    LEFT JOIN skygame.referral r 
        ON u.id_user = r.id_user
)
SELECT 
    total_players,
    successful_invites,
    -- K-factor = успешные регистрации / общее число игроков
    ROUND(successful_invites::DECIMAL / NULLIF(total_players, 0), 3) AS k_factor,
    -- Интерпретация: каждый игрок приводит k_factor новых игроков
    ROUND(successful_invites::DECIMAL / NULLIF(total_players, 0) * 100, 1) AS growth_potential_percent
FROM referral_stats;
