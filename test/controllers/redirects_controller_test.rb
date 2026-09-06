require "test_helper"

class RedirectsControllerTest < ActionDispatch::IntegrationTest
  test "redirects with 302 and records the click" do
    link = Link.create!(original_url: "https://example.com/landing", slug: "go-now")
    get short_url("go-now"), headers: { "Referer" => "https://twitter.com/x", "User-Agent" => "TestUA" }
    assert_response :found
    assert_redirected_to "https://example.com/landing"
    assert_equal 1, link.reload.clicks_count
    assert_equal "https://twitter.com/x", link.clicks.sole.referrer
  end

  test "unknown slug is a JSON 404" do
    get "/nope123"
    assert_response :not_found
    assert_equal({ "error" => "not found" }, response.parsed_body)
  end

  test "expired link is 410 Gone and not counted" do
    link = Link.create!(original_url: "https://example.com", slug: "old", expires_at: 1.hour.from_now)
    travel 2.hours do
      get short_url("old")
      assert_response :gone
    end
    assert_equal 0, link.reload.clicks_count
  end

  test "slugs outside the allowed format do not match the route" do
    get "/a"
    assert_response :not_found
  end
end
