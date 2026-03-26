# Script Library

A searchable web portal for SQL and Ruby scripts, hosted on GitHub Pages.

## Live Portal

Visit: `https://<your-username>.github.io/<repo-name>/`

## Structure

```
my-script-library/
├── index.html              ← Web portal (search, browse, view scripts)
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy.yml      ← Auto-deploys on every push to main
├── sql/
│   ├── reports/
│   ├── migrations/
│   └── utils/
└── ruby/
    ├── etl/
    ├── automation/
    └── utils/
```

## Adding a Script

1. Drop your `.sql` or `.rb` file into the right folder
2. Add an entry to the `SCRIPTS` array in `index.html`:

```js
{
  id: 10,
  lang: "sql",           // "sql" or "ruby"
  folder: "reports",     // subfolder name
  name: "my_script.sql",
  desc: "Short description of what this script does.",
  tags: ["tag1", "tag2"],
  author: "yourname",
  date: "2025-03-26",
  code: `...paste your script here...`
}
```

3. Push to `main` — GitHub Actions deploys automatically in ~30 seconds.

## Setup (first time)

1. Go to repo **Settings → Pages**
2. Under **Source**, select **GitHub Actions**
3. Push any change to `main` to trigger first deploy

## Team

Add your teammates as collaborators under **Settings → Collaborators**.
