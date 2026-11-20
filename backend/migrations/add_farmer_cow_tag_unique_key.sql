-- =============================================================================
-- Migration: Add composite unique key (farmer_id, cow_tag) to Cow table
-- Scopes cow tag uniqueness strictly per-farmer rather than globally
-- =============================================================================

USE mastitis_detection_system;

SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'Cow' 
      AND INDEX_NAME = 'uq_farmer_cow_tag'
);

SET @sql_stmt = IF(
    @idx_exists = 0,
    'ALTER TABLE Cow ADD UNIQUE KEY uq_farmer_cow_tag (farmer_id, cow_tag);',
    'SELECT "Index uq_farmer_cow_tag already exists in Cow" AS status;'
);

PREPARE stmt FROM @sql_stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
