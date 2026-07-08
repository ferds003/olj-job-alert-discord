# OLJAlerts 🚨

Automated job alerts for OnlineJobs.ph — get an email when a posting matches your keywords.

**Perfect for:** Job hunters who want instant notifications without constantly checking job boards.

---

## Architecture

```
OnlineJobs.ph → n8n (scrape) → Neon Postgres → n8n (match) → Email
```

- **n8n** runs locally (Windows), auto-started via pm2 + a Windows Task Scheduler entry at login — no manual step needed once your PC is on and connected to the internet.
- **Neon** hosts the Postgres database, so job history persists independent of local uptime.
- **Email (SMTP/Gmail)** delivers the alert — no bot, no external chat app required.

---

## What It Does

1. **Scrapes** OnlineJobs.ph once daily for new and recently-updated job postings
2. **Stores** every complete posting in a Neon-hosted Postgres database
3. **Matches** stored postings against a hardcoded keyword list (edited directly in the database — no self-serve bot/UI)
4. **Emails** you an HTML alert when a posting matches one of your keywords

---

## What You Need

- **n8n** (automation tool — runs locally via `npm install n8n`, no Docker/Linux server required)
- **Neon** (free hosted Postgres — https://neon.tech)
- **Gmail account with an App Password** (for SMTP sending — requires 2-Step Verification enabled)
- **pm2** (keeps n8n running in the background and restarts it on crash)
- **Node.js ≥22.22**

---

## How It Works

Think of it as a pipeline:
- **Stage 1:** Scrapes job listings once daily — `Workflow 0` walks the next ~500 sequential job IDs, `Workflow 0 (recently-updated)` scrapes the live search results page for anything not yet stored
- **Stage 2:** Stores everything in Neon Postgres (`job_postings` table)
- **Stage 3:** `Workflow 2` polls for unprocessed postings, matches them against `user_subscriptions` keywords using word-boundary regex
- **Stage 4:** On a match, the subworkflow sends you an HTML email via Gmail SMTP
- **Stage 5:** `Workflow 3` runs daily and deletes processed postings older than 30 days to keep the database small

---

## Project Status

**✅ Complete** (all workflows live in `n8n_discord/`):
- `Workflow 0 - OnlineJobs.ph Job Sync` — scrapes new job postings, once daily
- `Workflow 0 - OnlineJobs.ph Job Sync recently-updated` — scrapes the live search page for postings not yet stored, once daily
- `Workflow 2 - Job Alert Notifier` + subworkflow — matches keywords and sends email alerts
- `Workflow 3 - Cleanup` — daily deletion of old processed postings

**Not included** (intentionally, vs. the original Telegram-based upstream project): no Telegram bot, no Supabase logging, no self-serve subscription management. Keywords are managed by editing `user_subscriptions` directly via SQL.

---

## Managing Keywords

There's no bot or UI for this — edit `user_subscriptions` directly:

```sql
DELETE FROM user_subscriptions WHERE chat_id = 1;

INSERT INTO user_subscriptions (chat_id, keyword) VALUES
  (1, 'n8n'),
  (1, 'virtual assistant'),
  (1, 'react');
```

Run this against your Neon database (`psql "<your-neon-connection-string>"` or the Neon SQL console).

---

## Quick Setup (High Level)

1. **Create a Neon project** at neon.tech, and a dedicated database/role for this project.

2. **Create the schema:**
    ```bash
    psql "<your-neon-connection-string>" -f database/database_setup_neon.sql
    ```

3. **Install n8n locally:**
    ```bash
    npm install
    ```
    (n8n is a `package.json` dependency — this avoids relying on `npx`'s cache, which can resolve inconsistent/broken dependency versions.)

4. **Import workflows into n8n:**
   - Import all 5 workflow JSON files from `n8n_discord/`
   - Configure a Postgres credential pointing at your Neon database
   - Configure an SMTP credential (Gmail: `smtp.gmail.com`, port `465`, SSL, your Gmail address + App Password)
   - Activate the workflows

5. **Set up auto-start:**
    ```bash
    pm2 start ecosystem.config.js
    pm2 save
    ```
    Then register a Windows Task Scheduler entry (trigger: at log on) that runs `pm2-resurrect.cmd` — this brings n8n back up automatically every time you log in, with no visible window.

6. **Test it:**
   - Open `http://localhost:5678`, open a workflow, click "Test workflow" to run it immediately (bypasses the daily schedule)
   - Verify rows land in `job_postings`, then confirm you receive an email alert for a matching posting

---

## Notes

- **Daily batch size:** the "New Jobs" scraper checks ~500 sequential job IDs per run (up from a smaller batch when it ran every few minutes), to keep roughly the same daily coverage now that it only runs once a day
- **Keyword matching:** word-boundary regex, case-insensitive (e.g., 'ai' matches "AI specialist" but not "PAID")
- **Job validation:** only complete job postings (with description, type, compensation, date) are stored
- **Modular design:** each workflow operates independently through Postgres as the data bus — no direct workflow-to-workflow calls except the notifier → subworkflow split
- **Secrets:** the Neon connection string, Gmail App Password, and any other credentials live only in n8n's local encrypted credential store and a gitignored `.env` — never in a committed file

---

See `spec.md` for the original Telegram-based upstream design (kept for reference — several of its details, like Supabase logging and the Telegram bot, no longer apply to this fork) and `AGENTS.md` for repo conventions.
