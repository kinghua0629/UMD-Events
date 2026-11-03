---
type: decision
tags: [decision, dependencies, parsing]
status: accepted
date: 2026-11-02
---
# Decision: regex HTML helpers instead of SwiftSoup

The plan called for SwiftSoup for sites without RSS. During implementation, the two scraped sites
([[maryland-today]], [[umd-engineering]]) needed only anchors, a few meta tags and `<p>` text, so a ~150-line
`HTMLText` covers it with zero dependencies and a hand-written pbxproj with no SPM. **Revisit** if a source needs
real DOM traversal (nested selectors, tables).
