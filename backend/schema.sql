-- =============================================================================
-- Mastitis Detection System (MDS) — Database Schema Initialization
-- Target Engine: MySQL 8.0+
-- =============================================================================

CREATE DATABASE IF NOT EXISTS mastitis_detection_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mastitis_detection_system;

-- 1. Farmer Table
CREATE TABLE IF NOT EXISTS Farmer (
    farmer_id INT PRIMARY KEY AUTO_INCREMENT,
    fname VARCHAR(50) NOT NULL,
    lname VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farmer_email (email)
) ENGINE=InnoDB;

-- 2. Cow Table
CREATE TABLE IF NOT EXISTS Cow (
    cow_id INT PRIMARY KEY AUTO_INCREMENT,
    farmer_id INT NOT NULL,
    cow_tag VARCHAR(20) NOT NULL,
    breed VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    health_status ENUM('Healthy', 'At Risk', 'Pending') NOT NULL DEFAULT 'Pending',
    last_tested DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farmer_id) REFERENCES Farmer(farmer_id) ON DELETE CASCADE,
    UNIQUE KEY uq_farmer_cow_tag (farmer_id, cow_tag),
    INDEX idx_cow_farmer (farmer_id),
    INDEX idx_cow_status (health_status),
    INDEX idx_cow_last_tested (last_tested)
) ENGINE=InnoDB;

-- 3. Sensor_Reading Table
CREATE TABLE IF NOT EXISTS Sensor_Reading (
    reading_id INT PRIMARY KEY AUTO_INCREMENT,
    cow_id INT NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    pH DECIMAL(4,2) NOT NULL,
    electrical_conductivity DECIMAL(6,2) NOT NULL,
    reading_time DATETIME NOT NULL,
    FOREIGN KEY (cow_id) REFERENCES Cow(cow_id) ON DELETE CASCADE,
    INDEX idx_reading_cow (cow_id),
    INDEX idx_reading_time (reading_time)
) ENGINE=InnoDB;

-- 4. Detection_Result Table
CREATE TABLE IF NOT EXISTS Detection_Result (
    result_id INT PRIMARY KEY AUTO_INCREMENT,
    cow_id INT NOT NULL,
    reading_id INT UNIQUE NOT NULL,
    prediction ENUM('Mastitis Present', 'Mastitis Absent') NOT NULL,
    confidence_score DECIMAL(5,2) NULL,
    detection_time DATETIME NOT NULL,
    FOREIGN KEY (cow_id) REFERENCES Cow(cow_id) ON DELETE CASCADE,
    CONSTRAINT fk_detection_reading FOREIGN KEY (reading_id) REFERENCES Sensor_Reading(reading_id) ON DELETE CASCADE,
    INDEX idx_detection_cow (cow_id),
    INDEX idx_detection_time (detection_time)
) ENGINE=InnoDB;

-- 5. Alert Table
CREATE TABLE IF NOT EXISTS Alert (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    result_id INT UNIQUE NOT NULL,
    farmer_id INT NOT NULL,
    message VARCHAR(255) NOT NULL,
    status ENUM('Read', 'Unread') NOT NULL DEFAULT 'Unread',
    send_time DATETIME NOT NULL,
    FOREIGN KEY (result_id) REFERENCES Detection_Result(result_id) ON DELETE CASCADE,
    FOREIGN KEY (farmer_id) REFERENCES Farmer(farmer_id) ON DELETE CASCADE,
    INDEX idx_alert_farmer (farmer_id),
    INDEX idx_alert_status (status)
) ENGINE=InnoDB;

-- 6. OTP Codes Table (for 2FA and Password Reset)
CREATE TABLE IF NOT EXISTS otp_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose ENUM('login', 'reset_password') NOT NULL,
    expires_at DATETIME NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_purpose (email, purpose)
) ENGINE=InnoDB;

-- =============================================================================
-- Migration Statement for Existing Databases
-- Preserves existing Detection_Result records and adds confidence_score
-- =============================================================================
-- ALTER TABLE Detection_Result ADD COLUMN confidence_score DECIMAL(5,2) NULL AFTER prediction;
