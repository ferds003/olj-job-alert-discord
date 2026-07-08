-- OLJAlerts Database Setup Script (Neon variant)
--
-- Run this against the hosted Neon "oljalerts" database instead of
-- database_setup.sql. The job_alert_client role and oljalerts database
-- are already provisioned on Neon (via `neonctl roles create` /
-- `neonctl databases create`), so this script only creates schema —
-- no CREATE USER / CREATE DATABASE / \c needed, and the role already
-- owns this database so no ownership transfer is needed either.

-- Create tables
CREATE TABLE job_postings (
  id               SERIAL PRIMARY KEY,
  job_id           BIGINT NOT NULL UNIQUE,
  job_title        TEXT,
  job_description  TEXT,
  job_skills       TEXT,
  type_of_work     TEXT,
  compensation     TEXT,
  hours_per_week   TEXT,
  job_date         DATE,
  is_processed     BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_subscriptions (
  id          SERIAL PRIMARY KEY,
  chat_id     BIGINT NOT NULL,
  keyword     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(chat_id, keyword)
);

-- === Insert your OWN keywords FOR DISCORD HOOK ===
INSERT INTO user_subscriptions (chat_id, keyword) VALUES
  (1, 'electronics'),
  (1, 'PCB'),
  (1, 'Embedded Systems'),
  (1, 'Hardware'),
  (1, 'IoT'),
  (1, 'Robotics'),
  (1, 'AWS'),
  (1, '3D Product'),
  (1, 'Product Development'),
  (1, 'Web Scraping'),
  (1, 'CAD'),
  (1, 'Raspberry Pi');

-- Create indexes
CREATE INDEX idx_job_postings_job_id ON job_postings(job_id);
CREATE INDEX idx_job_postings_created_at ON job_postings(created_at DESC);
CREATE INDEX idx_job_postings_is_processed ON job_postings(is_processed);
CREATE INDEX idx_user_subscriptions_chat_id_keyword ON user_subscriptions(chat_id, keyword);

-- === Verification ===
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('job_postings', 'user_subscriptions');

\dt
