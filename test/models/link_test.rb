require "test_helper"

class LinkTest < ActiveSupport::TestCase
  test "generates a 7 character slug when none is given" do
    link = Link.create!(original_url: "https://example.com/a")
    assert_match(/\A[a-zA-Z0-9]{7}\z/, link.slug)
  end

  test "keeps a valid custom slug" do
    link = Link.create!(original_url: "https://example.com", slug: "my-Link_1")
    assert_equal "my-Link_1", link.slug
  end

  test "rejects bad slugs, reserved slugs and duplicates" do
    assert_not Link.new(original_url: "https://example.com", slug: "ab").valid?
    assert_not Link.new(original_url: "https://example.com", slug: "has space").valid?
    assert_not Link.new(original_url: "https://example.com", slug: "api").valid?

    Link.create!(original_url: "https://example.com", slug: "taken")
    dup = Link.new(original_url: "https://example.com", slug: "TAKEN")
    assert_not dup.valid?
    assert_includes dup.errors[:slug], "has already been taken"
  end

  test "only accepts http(s) URLs with a host" do
    assert Link.new(original_url: "http://example.com/x?y=1").valid?
    assert_not Link.new(original_url: "javascript:alert(1)").valid?
    assert_not Link.new(original_url: "ftp://example.com").valid?
    assert_not Link.new(original_url: "https://").valid?
    assert_not Link.new(original_url: "not a url at all").valid?
    assert_not Link.new(original_url: "").valid?
  end

  test "expiry must be in the future on create" do
    assert_not Link.new(original_url: "https://example.com", expires_at: 1.minute.ago).valid?
    link = Link.create!(original_url: "https://example.com", expires_at: 1.hour.from_now)
    assert_not link.expired?
    travel 2.hours do
      assert link.expired?
      assert_not_includes Link.active, link
    end
  end

  test "record_click! stores a click and bumps the counter cache" do
    link = Link.create!(original_url: "https://example.com")
    link.record_click!(referrer: "https://ref.example", user_agent: "UA", ip: "203.0.113.9")
    link.reload
    assert_equal 1, link.clicks_count
    click = link.clicks.sole
    assert_equal "https://ref.example", click.referrer
    assert_equal 32, click.visitor_hash.length
  end
end
