---
name: vetting-product-name
description: Use when choosing or vetting a product, app, or brand name before launch — e.g. picking between candidate names, checking if a name is free for App Store submission, or verifying domain/trademark availability. Triggers — KO 제품 이름, 앱 이름, 네이밍, 도메인 가용, 상표 검색, 앱스토어 중복. EN product name, app name, naming, domain availability, trademark search, App Store name collision.
---

# Vetting a Product Name

## Overview
Before committing to a product/app/brand name, run **4 checks**: (1) domain, (2) App Store name collision, (3) trademark, (4) pronunciation/searchability. Checks 1–2 are automated by `check-name.sh`; checks 3–4 need judgment, so you (the agent) run them with WebSearch + official registries.

A name passes only when ALL four are clear enough for the user's risk tolerance. Report findings per candidate; the final go/no-go is the user's call (and trademark clearance is ultimately a lawyer's).

## When to use
- User is picking or comparing candidate names for a product/app/site/brand.
- User asks "is this name free?" / "이 이름 써도 돼?" / before App Store submission or domain purchase.
- Not for: internal codenames, variable/function naming, or projects with no public/commercial release.

## Quick start
```bash
SKILL_DIR=~/.claude/skills/vetting-product-name
"$SKILL_DIR/check-name.sh" voxa dictum loqua          # one or many candidates
TLDS="com io net ai app co" "$SKILL_DIR/check-name.sh" myname   # override TLDs (default: com io net ai app)
COUNTRIES="us kr jp" "$SKILL_DIR/check-name.sh" myname          # override App Store storefronts (default: us kr)
```
Output per name: domain verdicts (✅ 가용 / ⛔ 등록됨 / ❓ 불명) + App Store matches (⛔ 정확일치 / ⚠️ 유사). Then do checks 3–4 yourself.

## The 4 checks

### 1. Domain — automated (`check-name.sh`)
Checks `.com .io .net .ai .app` by default (add `.net`/`.io` are included; extend via `TLDS`).
- `.com/.net/.ai/.app` → RDAP (fast, exact). `.io` → whois of the registry directly, because **RDAP returns a false 404 (looks available) for registered `.io` domains**.
- `❓ 불명` usually means a whois rate-limit or network blip — just re-run that name. Don't report it as available.

### 2. App Store name collision — automated (`check-name.sh`)
Uses the public iTunes Search API per storefront (`COUNTRIES`).
- `⛔ 정확일치` = an existing app's display name equals the candidate (whole name, or the part before `:` / `-`). Treat as **likely blocked or confusing**.
- `⚠️ 유사` = same keyword appears in other app names (context, not a blocker).
- Caveat: this reflects *published display names*, not Apple's submission-time uniqueness rule. A clean result still must be confirmed in **App Store Connect** when reserving the name.

### 3. Trademark — agent-driven (judgment)
Screen for conflicting marks, especially **Nice class 9** (software/apps) and **class 42** (SaaS/software services); add **class 38/41** if relevant.
1. `WebSearch`: `"<name>" trademark`, `"<name>" 상표`, `"<name>" app company`.
2. Check official registries (via WebFetch or by giving the user the link):
   - 🇰🇷 KIPRIS 상표검색 — https://www.kipris.or.kr (영문 http://eng.kipris.or.kr)
   - 🇺🇸 USPTO Trademark Search — https://tmsearch.uspto.gov
   - 🌍 WIPO Global Brand Database (multi-jurisdiction, fastest first pass) — https://branddb.wipo.int
3. Flag identical or confusingly-similar live marks in the relevant class/region.
> This is a **screen, not legal clearance.** Always tell the user that final clearance needs a trademark attorney before filing or spending on branding.

### 4. Pronunciation & searchability — agent-driven (judgment)
1. `WebSearch` the bare name. Is page 1 dominated by an existing strong brand/company? If yes, organic discovery will be hard (SEO collision).
2. Judge against this rubric:
   - **Spellable from hearing it** — can someone type it correctly after hearing it once? (avoid ambiguous vowels/silent letters)
   - **Pronounceable for the target market** (KO + EN here) with no awkward reading.
   - **No negative/unintended meaning** in major languages (quick WebSearch if unsure).
   - **Distinct** — not a generic dictionary word that's impossible to rank for or own.

## Output format
Summarize as a table the user can scan, one row per candidate:

| 후보 | 도메인(.com/.io/.net/.ai/.app) | 앱스토어 | 상표(KR/US) | 발음·검색성 | 종합 |
|------|-------------------------------|----------|-------------|-------------|------|
| Voxa | .com⛔ .io⛔ .net✅ .ai✅ .app✅ | ⚠️ 유사 다수 | 유사 마크 확인 필요 | 짧음·강함 | 조건부 |

End with a clear recommendation and the explicit caveats (App Store Connect confirmation + lawyer for trademark).

## Common pitfalls
- **Trusting RDAP for `.io`** → false "available". The script already forces whois for `.io`; keep it that way.
- **Reading `❓ 불명` as available** → it's a rate-limit/unknown; re-run, don't assume free.
- **Equating "App Store keyword match" with "name taken"** → only `⛔ 정확일치` matters; confirm in App Store Connect.
- **Calling a name "trademark-safe"** → you only screened. Defer the legal call to the user/attorney.
- **Ignoring SEO collision** → a name that's a common word or shares page 1 with a big brand is hard to market even if domain+trademark are free.
