# 07 — Marketing website

You are the web engineer and brand designer. Prompts 00 through 06 are done. Ship the public site. Do not build the admin studio in this prompt.

## Goal

A person who has never heard of Axiom understands the daily loop, the math-to-AI promise, and how to join the waitlist. The page feels like the product: paper, ink, one accent, Fraunces and Outfit.

## Routes

All inside the `(marketing)` route group. Server Components by default.

`/`

- Hero with the name Axiom, the sentence “Train the mind that trains the machine.”, and one primary action to the waitlist form on the same page.
- A short job story: five minutes, one idea, a robot ability at the end.
- Three steps that use real version-1 ideas: place an arrow, see how much two arrows agree, watch Pip match a pattern. Use simple inline SVG or CSS shapes that match `PipMark` geometry. Do not use a stock illustration pack.
- A path preview that reads published skill titles from the database when `DATABASE_URL` works. If the query fails during static generation, fall back to the seed titles compiled into a constant that matches the seed slugs.
- An FAQ with four questions: who it is for, how long a session is, whether the lessons cost money, and whether it is a chatbot. Answers: teens and adults, a few minutes, the path is free, you do the math yourself.
- Footer links to `/method`, `/privacy`, `/terms`.

`/method`

Explain a mission, specific feedback, spaced review in plain language (“old ideas come back just before they fade”), and placement. No mention of FSRS, XP formulas, or internal table names.

`/privacy`

Accurate for version 1: email and password accounts, profile, lesson results, streak, timezone, waitlist email. Analytics tools receive product events without the email address when keys are present. No sale of personal data. Contact email `privacy@axiom.app` as a placeholder that is easy to find and change.

`/terms`

Short terms of use: the service is educational practice, accounts are for the learner, content is owned by Axiom, do not abuse the API.

## Waitlist

Form posts to a Server Action `joinWaitlist(email)`.

- Validate with Zod. Invalid email returns a field error.
- Normalize to lowercase trimmed email.
- Insert into `waitlist_emails`. Unique violation returns success copy as well, so the form does not reveal whether an address was already stored. Log the duplicate at info level without treating it as a 500.
- If `RESEND_API_KEY` is set, send a one-line confirmation with Resend. If it is absent, store the row and skip sending.
- Success state replaces the form with “You are on the list.”

The form itself is a Client Component or a server form with `useActionState`. Keep the rest of the page as Server Components.

## SEO

- Metadata title and description on each page.
- Open Graph title, description, and a generated or static image using the paper background and the word Axiom.
- Canonical URLs from `BETTER_AUTH_URL` or a `NEXT_PUBLIC_SITE_URL` env key. Add the key to env parsing.
- `app/sitemap.ts` and `app/robots.ts`.

## Responsive and accessibility

Lay out for 375px and 1280px. One column on small screens. The hero text stays under four lines at 375px. Buttons meet the 56px height from the design system. Focus states visible. Form errors are tied to the input with `aria-describedby`. Color contrast of ink on paper and white-on-accent meets WCAG AA.

## UI

Build every visible control with shadcn/ui from `@/components/ui`: `Button` for the waitlist action, `Card` for the three steps, `Input` and `Label` for the email field, `Accordion` for the FAQ if you add that shadcn component. Pages stay Server Components and import those files directly. The waitlist form is the client leaf. Do not add Material UI, Chakra, Mantine, or custom button and input markup.

## Patterns

- No new ORM calls from components. A `getPublicPathTitles()` function in the content feature reads titles.
- Marketing does not import admin modules.
- Do not add a blog, auth UI, or pricing table.

## Out of scope

App store listings, localization, accounts on the marketing site, and the admin studio.

## Acceptance

- Invalid email shows an error and writes no row.
- A valid email writes one row. Submitting it again still shows success and keeps a single row.
- Local production build: accessibility score at least 95 on `/` in Lighthouse or an equivalent axe check with no serious violations.
- The layout holds at 375px and 1280px without horizontal scroll.
- `/design` remains unavailable in production.
