#!/usr/bin/env bash
# check-name.sh — 제품/앱/브랜드 이름의 도메인 + 앱스토어 동명 충돌을 조회한다.
#
# 사용법:
#   ./check-name.sh <name> [name2 ...]
#   TLDS="com io net ai app co" ./check-name.sh myname     # TLD 목록 변경
#   COUNTRIES="us kr jp" ./check-name.sh myname            # 앱스토어 국가 변경
#
# 판별 근거(검증됨):
#   - .com/.net/.ai/.app : RDAP(rdap.org) HTTP 200=등록됨, 404=가용. 그 외는 whois로 폴백.
#   - .io                : RDAP가 등록 도메인에도 빈 404를 반환(가용 오판)하므로 whois로만 판별.
#   - 앱스토어            : iTunes Search API(entity=software). 이름 정확일치는 ⛔, 부분일치는 ⚠️.
set -uo pipefail

TLDS="${TLDS:-com io net ai app}"
COUNTRIES="${COUNTRIES:-us kr}"

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
urlenc() { jq -rn --arg x "$1" '$x|@uri'; }

# RDAP: taken | available | unknown
rdap_status() {
  local code
  code=$(curl -s -L --max-time 15 -o /dev/null -w "%{http_code}" "https://rdap.org/domain/$1" 2>/dev/null)
  case "$code" in
    200) echo taken ;;
    404) echo available ;;
    *)   echo unknown ;;
  esac
}

# TLD별 레지스트리 whois 호스트. 비어 있으면 신뢰할 whois 경로 없음.
# (기본 whois는 IANA 서문 + 등록대행사 꼬리가 섞여 오탐하므로 레지스트리에 '직접' 질의한다.)
registry_host() {
  case "$1" in
    com|net) echo whois.verisign-grs.com ;;
    io)      echo whois.nic.io ;;
    ai)      echo whois.nic.ai ;;
    app)     echo whois.nic.google ;;
    co)      echo whois.nic.co ;;
    *)       echo "" ;;
  esac
}

# 레지스트리 직접 whois: taken | available | unknown (단일·정제된 응답이므로 가용 패턴 우선 검사 안전)
whois_status() {
  local domain="$1" host="$2" out
  [ -z "$host" ] && { echo unknown; return; }
  out=$(whois -h "$host" "$domain" 2>/dev/null)
  if printf '%s' "$out" | grep -qiE 'no match|not found|no object found|no entries found|not been registered|available for registration|status:[[:space:]]*(free|available)'; then
    echo available
  elif printf '%s' "$out" | grep -qiE 'creation date|created on|registry expiry|expir(y|ation) date|domain status:|registrar:|name ?server:'; then
    echo taken
  else
    echo unknown
  fi
}

domain_verdict() {
  local domain="$1" tld="${1##*.}" status host
  host=$(registry_host "$tld")
  if [ "$tld" = io ]; then
    # .io는 RDAP가 등록 도메인에도 빈 404를 반환 → whois만 신뢰
    status=$(whois_status "$domain" "$host")
  else
    status=$(rdap_status "$domain")
    [ "$status" = unknown ] && status=$(whois_status "$domain" "$host")
  fi
  case "$status" in
    available) printf '  %-22s ✅ 가용\n' "$domain" ;;
    taken)     printf '  %-22s ⛔ 등록됨\n' "$domain" ;;
    *)         printf '  %-22s ❓ 불명(수동 확인)\n' "$domain" ;;
  esac
}

appstore_check() {
  local name="$1" name_lc; name_lc=$(lc "$name")
  local country json
  for country in $COUNTRIES; do
    json=$(curl -s --max-time 15 "https://itunes.apple.com/search?term=$(urlenc "$name")&entity=software&country=${country}&limit=25" 2>/dev/null)
    [ -z "$json" ] && { printf '  [%s] 조회 실패\n' "$country"; continue; }
    local n; n=$(printf '%s' "$json" | jq -r '.resultCount // 0')
    if [ "$n" = 0 ]; then printf '  [%s] 동명/유사 앱 없음 ✅\n' "$country"; continue; fi
    # 정확일치: trackName 전체 또는 ':'/'-'/'—' 앞부분이 이름과 동일
    printf '%s' "$json" | jq -r '.results[] | "\(.trackName)\t\(.sellerName)"' | while IFS=$'\t' read -r track seller; do
      local head; head=$(lc "$track" | sed -E 's/[:–—-].*//; s/^[[:space:]]+//; s/[[:space:]]+$//')
      if [ "$(lc "$track")" = "$name_lc" ] || [ "$head" = "$name_lc" ]; then
        printf '  [%s] ⛔ 정확일치: %s  — %s\n' "$country" "$track" "$seller"
      else
        printf '  [%s] ⚠️  유사: %s  — %s\n' "$country" "$track" "$seller"
      fi
    done
  done
}

for name in "$@"; do
  echo "════════════════════════════════════════"
  echo "이름: $name"
  echo "── 도메인 ──"
  for tld in $TLDS; do domain_verdict "$(lc "$name").${tld}"; done
  echo "── 앱스토어(iTunes Search) ──"
  appstore_check "$name"
  echo
done
