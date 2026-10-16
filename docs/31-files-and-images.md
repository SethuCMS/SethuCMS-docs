# 31. Images and files

Images and PDFs can be stored in the connected database and used from any field that holds a file. The first adapter that offers this is Firestore. Other databases do not offer it, and the admin app only shows the upload button when the connection can store files.

**Status:** tested against a fake Firestore. Try it against a real project before relying on it.

## Endpoints

| Method | Path | Who | Purpose |
|---|---|---|---|
| POST | `/v1/connections/{id}/files` | editor, admin | Upload raw bytes |
| GET, HEAD | `/v1/files/{id}/{fileId}` | anyone with the link (public) or any token (private) | Download |
| DELETE | `/v1/connections/{id}/files/{fileId}` | admin | Remove |

A file field in a record holds a small object such as `{ "asset": "...", "url": "...", "alt": "..." }`. The admin app shows a preview, a Replace button and a Private checkbox. The raw object is available behind **Edit as code**.

## What is allowed

PNG, JPEG, WebP, GIF, SVG and PDF, up to 4 MB (serverless hosts cap a request at about 4.5 MB).

## Safety rules

- **The type comes from the bytes.** The gateway reads the first bytes and refuses a file whose content does not match what the caller said, so a web page cannot be slipped in as an image.
- **Hidden data is cut out.** Images lose camera and GPS data, author and software tags, comments, thumbnails and anything appended after the end of the image. The picture is not decoded or re-compressed, so quality is unchanged. Only the rotation is kept, so phone photos stay upright.
- **PDFs that can run something are refused:** JavaScript, launch actions, embedded files, forms that submit data and rich media. This is a filter, not a guarantee. A PDF that cannot be read well enough to check is refused.
- **Malformed files are refused.** The gateway never guesses about a file it cannot parse.
- **Public links cannot be guessed** (128 random bits), but anyone with the link can read the file, like any "anyone with the link" share. A file uploaded with `X-File-Access: private` is served only to a caller who sends a valid token, and looks missing to everyone else.

## Limits

| Setting | Default | Meaning |
|---|---|---|
| `SETHUCMS_FILE_STORAGE_MB` | 100 | Total storage per connection |
| `SETHUCMS_FILE_DAILY_MB` | 50 | Upload volume per caller per day |
| `SETHUCMS_FILE_DAILY_COUNT` | 100 | Uploads per caller per day |

## Moving files out of Sanity

Content that still links to `cdn.sanity.io` can be copied into the connection with the sync script (`sync-sanity-to-cms.mts`, kept in the website project that owns the Sanity content). Run it as a dry run first, then with `--apply --force`. After it runs, the records point at gateway links instead.
