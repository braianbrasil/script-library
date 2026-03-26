# Script Library

Searchable portal for SQL and Ruby scripts — hosted on GitHub Pages.

**Live portal:** `https://braianbrasil.github.io/script-library/`

## Folder structure

```
script-library/                        ← root of the repo
├── index.html                         ← portal (never edit this)
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy.yml                 ← auto-builds and deploys on push
│
├── sql/                               ← one folder per SQL script
│   ├── monthly_revenue_report/
│   │   ├── monthly_revenue_report.sql
│   │   └── monthly_revenue_report.json
│   └── active_users_daily/
│       ├── active_users_daily.sql
│       └── active_users_daily.json
│
└── ruby/                              ← one folder per Ruby script
    └── sync_customers_to_crm/
        ├── sync_customers_to_crm.rb
        └── sync_customers_to_crm.json
```

## Adding a new script

**Step 1** — Create a folder inside `sql/` or `ruby/` with the script name:

```
sql/my_new_query/
```

**Step 2** — Add your script file:

```
sql/my_new_query/my_new_query.sql
```

**Step 3** — Add a metadata `.json` file with the same name:

```json
{
  "name": "my_new_query.sql",
  "lang": "sql",
  "folder": "reports",
  "desc": "Short description of what this script does.",
  "tags": ["tag1", "tag2"],
  "author": "yourname",
  "date": "2025-03-26"
}
```

**Step 4** — Push:

```bash
git add .
git commit -m "add: my_new_query"
git push
```

GitHub Actions builds `index.json` automatically and the portal updates in ~30 seconds. You never touch `index.html`.

---

### JSON fields

| Field    | Required | Description                              |
|----------|----------|------------------------------------------|
| `name`   | yes      | Filename including extension             |
| `lang`   | yes      | `"sql"` or `"ruby"`                      |
| `folder` | yes      | Category label shown in the portal       |
| `desc`   | yes      | Short description (1-2 sentences)        |
| `tags`   | yes      | Array of lowercase tags                  |
| `author` | yes      | Your username or initials                |
| `date`   | yes      | Date in `YYYY-MM-DD` format              |

---

## First-time GitHub Pages setup

1. Go to your repo on GitHub
2. Click **Settings → Pages**
3. Under **Source**, select **GitHub Actions**
4. Push any change to `main` to trigger the first deploy
