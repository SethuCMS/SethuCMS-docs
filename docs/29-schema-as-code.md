# 29. Schema as code

Your database says what exists. A schema file says how it is edited, the way a
Sanity Studio schema does. It never creates, renames or drops anything in your
database, and it can only tighten rules, never loosen what the database already
requires.

## Turn it on

    SETHUCMS_SCHEMA_FILE=./sethucms.schema.mjs    # .json, .mjs or .js (.ts on Node 23.6+)
    SETHUCMS_SCHEMA='{"collections":[...]}'       # or the same thing inline, as JSON

A wrong file stops the gateway from starting, with a message naming the
problem. Restart the gateway after editing the file.

## Example

    export default {
      collections: [
        {
          name: 'certificates',
          title: 'Certificates',
          titleField: 'title',
          fields: [
            { name: 'title', required: true, maxLength: 120 },
            { name: 'issuer' },
            { name: 'order', type: 'integer' },
            { name: 'url', label: 'Certificate link' },
            { name: 'image', widget: 'image' },
            { name: 'sanity_id', hidden: true },
            { name: 'sanity_updated_at', hidden: true, readOnly: true },
          ],
        },
      ],
    };

## Settings

Collection: `name`, `title`, `titleField`, `strict` (show only the fields listed
here), `fields`.

Field: `name`, `type` (only checked against the database), `label`,
`description`, `widget` (`text`, `textarea`, `code`, `image`, `file`), `hidden`,
`readOnly`, `required`, `min`, `max`, `minLength`, `maxLength`, `options`.

- `readOnly`, `required` and the limits are enforced by the gateway on every
  write, not just in the form.
- `hidden` only decides what the form shows first. A person can show the field
  from the "Fields" control. To keep a value away from a role, use roles and
  field rules instead.
- `required: false` and wider limits cannot loosen the database's own rules.

Admins see the loaded file and where it differs from each connection under
Settings, Schema.
