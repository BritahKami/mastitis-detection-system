-- =============================================================================
-- Migration: Add confidence_score to Detection_Result table
-- Target: MySQL 8.0+
-- Preserves existing detection records while supporting model confidence scores
-- =============================================================================

USE mastitis_detection_system;

-- Add confidence_score column if not already present
-- For MySQL versions supporting IF NOT EXISTS:
-- ALTER TABLE Detection_Result ADD COLUMN IF NOT EXISTS confidence_score DECIMAL(5,2) NULL AFTER prediction;

-- Standard Safe Migration statement:
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'Detection_Result' 
      AND COLUMN_NAME = 'confidence_score'
);

SET @sql_stmt = IF(
    @col_exists = 0,
    'ALTER TABLE Detection_Result ADD COLUMN confidence_score DECIMAL(5,2) NULL AFTER prediction;',
    'SELECT "Column confidence_score already exists in Detection_Result" AS status;'
);

PREPARE stmt FROM @sql_stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
