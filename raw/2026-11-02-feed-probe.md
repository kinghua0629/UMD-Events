# Feed probe — 2026-11-02 (curl, UA "Mozilla/5.0")

| URL | Result |
|---|---|
| https://today.umd.edu/rss.xml | 404 |
| https://today.umd.edu/feed | 404 (no RSS `<link>` in homepage either) |
| https://dbknews.com/feed/ | 200 application/rss+xml (WordPress, has content:encoded) |
| https://umterps.com/rss?path=general | 200 application/xml (RSS 2.0, description starts with `<img>`) |
| https://umterps.com/rss.aspx | 200, empty content type |
| https://calendar.umd.edu/rss, /ical, /events.ics, /api/events | 404 |
| https://calendar.umd.edu/feed | 200 but HTML (site is a JS app: `<umd-feed-events-grouped>` web component) |
| https://terplink.umd.edu/events.rss | 200 application/rss+xml (Campus Labs Engage, public events ~6 weeks out) |
| https://terplink.umd.edu/events.ics | 200 text/calendar (folded lines, UTC times, UID = event URL, X-HOSTS) |
| https://www.cs.umd.edu/news/rss.xml | 200 but HTML |
| https://www.cs.umd.edu/feeds/news/all | 200 RSS 2.0 (found via `href="/feeds/news/all"` on /news) |
| https://cmns.umd.edu/news-events/news/rss.xml | 404 |
| https://eng.umd.edu/news/rss | 404 |

## HTML structure notes
- today.umd.edu homepage: story links are `<a href="https://today.umd.edu/<slug>">`; the text link has
  `aria-label="Read More about <Title>"`, image links have `aria-label="<Title>: <image alt> Thumbnail"`.
  Article pages have `article:published_time`, `og:description`; `og:title` is just "Maryland Today".
- eng.umd.edu/news: `<a href="/news/story/<slug>" aria-label="Read more about <Title>">` (titles may be truncated
  with "..."); some cards render "October 23, 2026  Title" as link text. Some story pages have no publish-date meta,
  and og:title is double-encoded (`&amp;amp;`).

## Live parser run (same day)
All 6 default sources parsed: Maryland Today 16, Diamondback 10, TerpLink 150 (before horizon fix), Athletics 10,
CS 50, Engineering 10. TerpLink initially listed semester-long "events" that started in August.
