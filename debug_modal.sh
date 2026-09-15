#!/bin/bash
# Login and check the rendered HTML
curl -s -L -c /tmp/cookies.txt -b /tmp/cookies.txt 'http://localhost:4066/Account/Login' > /tmp/login.html
TOKEN=$(grep -o 'name="__RequestVerificationToken" value="[^"]*"' /tmp/login.html | head -1 | sed 's/.*value="//;s/"//')
echo "Token: ${TOKEN:0:20}..."

# Login
curl -s -L -c /tmp/cookies.txt -b /tmp/cookies.txt \
  --data-urlencode "IdNo=12345678" \
  --data-urlencode "Password=Test@123" \
  --data-urlencode "__RequestVerificationToken=$TOKEN" \
  'http://localhost:4066/Account/Login' -o /dev/null -w 'Login: %{http_code}\n'

# Fetch comprehensive settings page
curl -s -b /tmp/cookies.txt 'http://localhost:4066/Pricing/Comprehensive' > /tmp/comp.html
echo "Page size: $(wc -c < /tmp/comp.html) bytes"
echo "Modal divs: $(grep -c 'id=\"bandModal\"\|id=\"benefitModal\"\|id=\"limitModal\"' /tmp/comp.html)"
echo "Bootstrap JS loaded: $(grep -c 'bootstrap.min.js' /tmp/comp.html)"
echo "jQuery loaded: $(grep -c 'jquery' /tmp/comp.html)"
echo "openBandModal: $(grep -c 'openBandModal' /tmp/comp.html)"
echo "--- Modal HTML snippet ---"
grep -A5 'id="bandModal"' /tmp/comp.html | head -8
echo "--- JS section snippet ---"
grep -A3 'DOMContentLoaded' /tmp/comp.html | head -5
