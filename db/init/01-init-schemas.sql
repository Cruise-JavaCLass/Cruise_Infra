-- =============================================================================
-- Cruise Management System - Database Bootstrap Initialization Script
-- Initializes schema isolation, extensions, and standard maritime roles
-- =============================================================================

-- 1. Create dedicated schemas for microservices isolation
CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS itinerary_schema;
CREATE SCHEMA IF NOT EXISTS activity_schema;
CREATE SCHEMA IF NOT EXISTS pos_schema;

-- 2. Enable common extensions for UUID and cryptographic functions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 3. Grant schema permissions to the current application user
GRANT ALL ON SCHEMA auth_schema TO CURRENT_USER;
GRANT ALL ON SCHEMA itinerary_schema TO CURRENT_USER;
GRANT ALL ON SCHEMA activity_schema TO CURRENT_USER;
GRANT ALL ON SCHEMA pos_schema TO CURRENT_USER;
