// pm2 process definition for n8n, so it auto-restarts on crash and can be
// registered to start on Windows boot (see README/AGENTS notes for the
// `pm2 start`, `pm2 save`, `pm2 startup` commands to run once this is ready).
const fs = require("fs");
const path = require("path");

function loadEnvFile(filePath) {
  const env = {};
  if (!fs.existsSync(filePath)) return env;
  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx === -1) continue;
    env[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
  }
  return env;
}

const envFromDotenv = loadEnvFile(path.join(__dirname, ".env"));

module.exports = {
  apps: [
    {
      name: "n8n",
      script: "node_modules/n8n/bin/n8n",
      args: "start",
      cwd: __dirname,
      env: {
        ...envFromDotenv,
      },
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
  ],
};
