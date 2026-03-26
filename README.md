# Script Library

Searchable portal for SQL and Ruby scripts — hosted on GitHub Pages.

**Live portal:** `https://braianbrasil.github.io/script-library/`

## Adding a new script

1. Drop your `.sql` or `.rb` file in the right folder:
   - `sql/reports/`, `sql/migrations/`, `sql/utils/`
   - `ruby/etl/`, `ruby/automation/`, `ruby/utils/`

2. Create a `.json` file with the **same name** next to it:

```json
{
  "name": "my_script.sql",
  "lang": "sql",
  "folder": "reports",
  "desc": "Short description of what this script does.",
  "tags": ["tag1", "tag2"],
  "author": "yourname",
  "date": "2025-03-26"
}
```

3. `git add . && git commit -m "add: my_script" && git push`

GitHub Actions builds `index.json` automatically and deploys in ~30s.

## First-time setup

1. Repo → **Settings → Pages** → Source: **GitHub Actions**
2. Push to `main` to trigger first deploy
