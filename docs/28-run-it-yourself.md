# 28. Run SethuCMS yourself, on your own database

SethuCMS does not host your data, and it does not host you. You run the gateway next to your database, and your content stays where it already is. We give you the software, the admin panel and these instructions.

This is the same shape people know from other CMS dashboards, with one difference: your data never moves to us.

| In a hosted CMS dashboard | In SethuCMS |
|---|---|
| Project | Your own SethuCMS gateway, running on your machine or server |
| Members and roles | **Roles and access, People**: one account per person, with Admin, Editor or Viewer |
| Datasets | **Connections**: your PostgreSQL, MySQL, SQLite, MongoDB or Firestore |
| Studio | The admin panel, served by your gateway |
| API tokens | **Roles and access, API tokens**, for your website or app |
| Activity log | **Audit log** |

## What you need

- Node.js 22 or newer and pnpm 9 (`corepack enable`)
- The four repositories side by side in one folder: `sethucms`, `sethucms-adapter-sdk`, `sethucms-adapters`, `sethucms-admin`
- Network access from the gateway to your database. If the database is on the same machine or the same private network, you are done. If it is in the cloud, allow the gateway's address in the database firewall.

## Step 1. Start the gateway

```sh
cd sethucms
sh scripts/build-all.sh     # a few minutes the first time
sh scripts/run-local.sh     # http://127.0.0.1:8080
```

The first start prints an admin token **once**. Copy it. It is only for the first sign-in, in the next step.

## Step 2. Create your own admin account

1. Open http://127.0.0.1:8080 and paste the admin token.
2. Go to **Roles and access**, then **People**, and add yourself as **Admin**.
3. Scan the setup key with Google Authenticator (or any authenticator app).
4. Sign out, then sign in with your username and the six-digit code.
5. Under **API tokens**, revoke the first admin token. From now on, everyone signs in as themselves.

Add each teammate the same way. Give them **Editor** to work with content or **Viewer** to read only. You cannot remove or demote the last admin.

## Step 3. Connect your database

1. Go to **Connections, New connection** and pick your database.
2. Fill in the host, database name and a database user with the fewest rights it can have. For PostgreSQL, a user that can only read the tables you want to expose is enough to start.
3. Choose **read-only**. Switch to read-write later, when you are sure.
4. Expose one table (a collection) and open it under **Content**.

| Database | Status |
|---|---|
| PostgreSQL | Tested against the real database |
| SQLite | Tested against the real database |
| MySQL, MariaDB, MongoDB | Tested against compatible servers only. Try on a copy of your data |
| Firestore | Tested against a fake only. Experimental |
| SQL Server | **Not supported yet** |

## Step 4. Use the content in your website or app

Under **Roles and access, API tokens**, create a **Viewer** token for your website and keep it in your server's environment variables, never in browser code. Then follow doc 25.

## Keep it safe

- Run the gateway behind HTTPS if anyone outside your machine can reach it. Doc 15 has the steps.
- Back up your data folder while the gateway is stopped: `sh scripts/backup.sh`.
- Run one gateway per data folder.
- Never paste tokens, passwords or database addresses into an issue.

## If the admin panel opens but shows no content

The gateway is only a window onto the connections you added. If **Content** says "No collections", the connection is empty, points at the wrong database, or no collection has been exposed yet. Check the connection's database name and expose a collection.

## Known gaps

- The Docker image has not been run end to end. The steps above are the tested path.
- There is no first-run setup screen yet. The first sign-in uses the printed token, as in Step 2.
- There is no SQL Server adapter yet.
