# 20. Sponsorship and funding

SethuCMS is free, open-source software (MIT licence). Sponsorship is how people who use it can help keep it maintained. This page says how funding is set up, what it pays for, and what sponsors do and do not get.

This page is a plan and a set of rules, not legal or tax advice. Items marked **check** were not verified.

## Where the money can go

| Route | Fits now? | Notes |
|---|---|---|
| **GitHub Sponsors on your personal profile** (`kasinadhsarma`) | **Yes, start here** | GitHub lists India as a supported region. Signing up needs an Indian bank account. Sponsorships from personal accounts carry no GitHub fee. Sponsorships from organisation accounts can carry fees of up to 6% (card and service), lower if they pay by invoice. |
| GitHub Sponsors for the **SethuCMS organisation** | Not yet | GitHub requires an organisation to be legally operating in a supported region. A GitHub organisation alone, with no registered entity behind it, is not enough. Revisit if you later register one. **check** with GitHub's current rules when you do. |
| Open Collective with a fiscal host | Later | A host holds the money and does the paperwork for a project. Whether a host will take an India-based project without a registered entity, and the host's fee, are **check**. |
| Other tip jars (Liberapay, Ko-fi and similar) | Optional | Add only if people ask. Each one is another account to run and report. |
| Grants and programmes for open source | Later | Many require a project that is already used by real people, and some require a registered organisation. **check** each one. |

## Setting it up (you do these steps)

1. **GitHub Sponsors:** open https://github.com/sponsors and apply for your personal profile. GitHub will ask for payout details and tax information. These are your own financial details, so enter them yourself and never share them in chat or in an issue.
2. **Profile text:** say what SethuCMS is, what the money pays for (below), and that it is free software with no paid features.
3. **Tiers:** a one-time option and two or three monthly options are enough. Suggested shape (you decide the amounts):

   | Tier | What the sponsor gets |
   |---|---|
   | Backer | A thank-you, and a name in `SPONSORS.md` if they agree |
   | Supporter | The same, and a name or logo in the README if they agree |
   | Organisation sponsor | The same, plus a link to their site in the README |

   Nothing in any tier changes what the software does or what anyone can use.
4. **Button:** put `org-github/FUNDING.yml` in the root of the organisation's `.github` repository so every repository shows a Sponsor button.
5. **Ask a chartered accountant** before you accept money: how sponsorship income is reported, whether foreign payments have any rules or limits, and when a registered entity would make sense. **check**

## What the money pays for

- Test servers and services (real MySQL, MongoDB, Firestore and cloud databases for the adapter tests)
- A domain name and hosting for the docs
- An independent security review before a stable release
- Small fixed rewards for accepted contributions, if you choose to offer them

Publish a short summary of income and spending each quarter, even if it is two lines.

## Rules for sponsors

- **Sponsors cannot buy decisions.** Money does not buy roadmap control, security exceptions, early access to vulnerabilities, or changes to the licence.
- **No access to anyone's data.** Sponsors never get access to a deployment, a database or logs.
- **No paid features.** The software stays free. Support requests from sponsors are answered in the same queue as everyone else's.
- **Names are opt-in.** A sponsor's name or logo appears in the README or `SPONSORS.md` only if they agree. A name can be personal data under GDPR, so remove it on request.
- **You may decline a sponsor** whose business or conduct conflicts with the project. Say so plainly and refund if the platform allows it.
- **Security reports are never for sale.** Reports go to the private channel in `SECURITY.md`, from sponsors or anyone else.

## Before you ask for money

People sponsor software they trust. Before you announce this, the project should have a version someone else can install and run. Until the Docker image is verified and the adapters other than PostgreSQL and SQLite have been tried on real servers, ask for feedback first and sponsorship second.

## Open questions for you

- Which amounts for the tiers?
- Do you want to offer contribution rewards, or keep all money for infrastructure and the security review?
- Do you plan to register an entity later (company, trust or society)? That decides whether to move to an organisation sponsor profile or a fiscal host.
