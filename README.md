# User Ban Status API (RoR + Tools Challenge)

This is a Ruby on Rails 8 API-only application built to evaluate user risk and determine ban statuses based on device integrity, geographical location, and network reputation.

## 🎯 Challenge Objectives Achieved

* **Endpoint Generation:** Created a strict `POST /v1/user/check_status` endpoint accepting and returning structured JSON.
* **Security Chain:** Implemented a three-tier security check:
1. Rooted device evaluation.
2. Cloudflare `CF-IPCountry` header validation against a Redis whitelist.
3. VPN/Tor network detection via the `vpnapi.io` external API.


* **Performance & Resilience:** The external VPN API responses are cached in Redis for 24 hours. API rate limits or network crashes are rescued gracefully, allowing the request to safely pass.
* **Database Architecture:** PostgreSQL is used for persistence.
* The `User` model uses a string-backed enum for `ban_status` to allow future states (e.g., `suspended`, `shadow_banned`).
* The `IntegrityLog` model acts as an append-only audit ledger.


* **Future-Proofing:** Logging is abstracted into an `IntegrityLoggerService` so data streams can be easily re-routed to Kafka, Datadog, or S3 in the future without touching core logic.

## 🧪 Methodology: Test-Driven Development (TDD)

This project was built using a strict Red-Green-Refactor TDD approach.

* **RSpec** is used for unit and request testing.
* **WebMock** is utilized to intercept and stub all external HTTP requests to `vpnapi.io`, ensuring the test suite runs fast, offline, and without consuming API quotas.
* **Service Objects** (`UserVerificationService`) isolate complex business logic from the controller, making it easily testable and maintainable.

---

## 🚀 Setup & Installation

### 1. Prerequisites

Ensure you have the following installed and running on your machine:

* Ruby (v3.2+)
* PostgreSQL (v14+)
* Redis

### 2. Environment Setup

Clone the repository and install dependencies:

```bash
bundle install

```

Configure your secure environment variables. Copy the example file and add your real VPNAPI key:

```bash
cp .env.example .env
# Open .env and add your real VPNAPI_KEY

```

Setup the database:

```bash
rails db:create db:migrate

```

### 3. Seed the Redis Whitelist

The application requires allowed countries to exist in Redis. Seed your local instance using the Redis CLI:

```bash
redis-cli SADD whitelist:countries "US" "CA" "GB" "PT"

```

---

## ⚙️ Running Automated Tests

Run the full RSpec test suite to verify models, services, integrations, and external API mocking:

```bash
bundle exec rspec

```

---

## 🕹️ Manual Testing Scenarios

To manually verify the edge cases, start your local Rails server:

```bash
rails server

```

Open a new terminal window and use the following `curl` commands to simulate incoming Cloudflare requests.

### Scenario 1: The "Happy Path" (Clean User)

Tests a valid user from a whitelisted country with a clean IP.

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
-H "Content-Type: application/json" \
-H "CF-IPCountry: US" \
-H "X-Forwarded-For: 8.8.8.8" \
-d '{
  "idfa": "user-1-clean",
  "rooted_device": false
}'

```

> **Expected:** `{"ban_status":"not_banned"}`

### Scenario 2: Rooted Device Check

Tests immediate failure based on device integrity.

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
-H "Content-Type: application/json" \
-H "CF-IPCountry: US" \
-H "X-Forwarded-For: 8.8.8.8" \
-d '{
  "idfa": "user-2-rooted",
  "rooted_device": true
}'

```

> **Expected:** `{"ban_status":"banned"}`

### Scenario 3: Cloudflare Country Whitelist

Tests rejection if the `CF-IPCountry` header is missing or not in the Redis Set (e.g., "RU").

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
-H "Content-Type: application/json" \
-H "CF-IPCountry: RU" \
-H "X-Forwarded-For: 8.8.8.8" \
-d '{
  "idfa": "user-3-bad-country",
  "rooted_device": false
}'

```

> **Expected:** `{"ban_status":"banned"}`

### Scenario 4: Existing Banned User (Short-Circuit)

Re-uses the IDFA from Scenario 2 to prove the app skips network checks and immediately returns banned. Note how we pass a clean country and unrooted device this time.

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
-H "Content-Type: application/json" \
-H "CF-IPCountry: US" \
-H "X-Forwarded-For: 8.8.8.8" \
-d '{
  "idfa": "user-2-rooted",
  "rooted_device": false
}'

```

> **Expected:** `{"ban_status":"banned"}` *(Check server logs to verify no external APIs were hit)*

### Scenario 5: External VPN/Tor Check & Redis Caching

Tests a known Tor node IP to verify the external API integration and caching.

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
-H "Content-Type: application/json" \
-H "CF-IPCountry: US" \
-H "X-Forwarded-For: 185.220.101.4" \
-d '{
  "idfa": "user-5-vpn",
  "rooted_device": false
}'

```

> **Expected:** `{"ban_status":"banned"}`

**To verify the Redis 24-hour cache worked:**

Here is the corrected section for your `README.md`, updated with the exact namespace (`rails:`) and the expected binary serialization output:

**To verify the Redis 24-hour cache worked:**

1. Inspect the key inside Redis Database 1 using the standard Rails namespace prefix:
```bash
redis-cli -n 1 GET "rails:vpn_cache:185.220.101.4"

```

*Note: Because Rails automatically binary-serializes entries using Marshal, the output will appear as a raw byte string ending in `\x04\bT` (where `T` stands for `true`).*

Alternatively, read the un-serialized value cleanly through the Rails console:
```ruby
rails console
Rails.cache.read("vpn_cache:185.220.101.4") # => true
```

2. Run the exact same `curl` command above again, but change the `idfa` to `"user-5-vpn-retry"`. Watch your Rails logs: you will see it instantly returns `banned` directly from the cache without executing an outbound HTTP request to VPNAPI.

### Verifying the Integrity Audit Logs

To ensure the `IntegrityLoggerService` correctly recorded these events, open the Rails console:

```bash
rails console

```

View the audit trail:

```ruby
# Count total logs
IntegrityLog.count

# View the log for a specific scenario
IntegrityLog.where(idfa: 'user-3-bad-country').first.attributes

```