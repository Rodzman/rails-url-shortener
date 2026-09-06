# Dedicated in-memory store for controller rate limiting so it works even when
# the app cache is the null store (as it is in the test environment). For a
# multi-process deployment swap this for a shared store such as Solid Cache or Redis.
RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 32.megabytes)
