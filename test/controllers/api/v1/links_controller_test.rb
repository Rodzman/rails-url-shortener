require "test_helper"

module Api
  module V1
    class LinksControllerTest < ActionDispatch::IntegrationTest
      setup { RATE_LIMIT_STORE.clear }

      test "creates a link and returns its short url" do
        post api_v1_links_url, params: { url: "https://example.com/path" }, as: :json
        assert_response :created
        body = response.parsed_body
        assert_equal "https://example.com/path", body["original_url"]
        assert_match(%r{\Ahttp://www\.example\.com/[a-zA-Z0-9]{7}\z}, body["short_url"])
        assert_equal 0, body["clicks_count"]
        assert_nil body["expires_at"]
      end

      test "accepts a custom slug and expiry" do
        expires = 1.day.from_now.change(usec: 0)
        post api_v1_links_url, params: { url: "https://example.com", slug: "launch", expires_at: expires.iso8601 }, as: :json
        assert_response :created
        assert_equal "launch", response.parsed_body["slug"]
        assert_equal expires.iso8601, response.parsed_body["expires_at"]
      end

      test "returns validation errors as 422" do
        post api_v1_links_url, params: { url: "javascript:alert(1)", slug: "!" }, as: :json
        assert_response :unprocessable_entity
        errors = response.parsed_body["errors"]
        assert_match(/http or https/, errors["original_url"].first)
        assert_match(/3-32 characters/, errors["slug"].first)
      end

      test "shows a link by slug and 404s for unknown slugs" do
        link = Link.create!(original_url: "https://example.com", slug: "known")
        get api_v1_link_url(link)
        assert_response :success
        assert_equal "known", response.parsed_body["slug"]

        get api_v1_link_url("missing")
        assert_response :not_found
        assert_equal({ "error" => "not found" }, response.parsed_body)
      end

      test "stats aggregate clicks per day and referrer" do
        link = Link.create!(original_url: "https://example.com", slug: "stats")
        travel_to Time.zone.parse("2026-09-06 12:00:00 UTC") do
          link.record_click!(referrer: "https://a.example", user_agent: "UA", ip: "1.1.1.1")
          link.record_click!(referrer: "https://a.example", user_agent: "UA", ip: "2.2.2.2")
          link.record_click!(referrer: nil, user_agent: "UA", ip: "1.1.1.1")
          link.record_click!(referrer: "https://b.example", user_agent: "UA", ip: "3.3.3.3")
          link.clicks.order(:id).last.update_columns(created_at: 2.days.ago)

          get stats_api_v1_link_url(link)
          assert_response :success
          body = response.parsed_body
          assert_equal 4, body["total_clicks"]
          assert_equal 2, body["unique_visitors_today"]
          assert_equal 7, body["last_7_days"].length
          assert_equal({ "date" => "2026-09-06", "clicks" => 3 }, body["last_7_days"].last)
          assert_equal({ "date" => "2026-09-04", "clicks" => 1 }, body["last_7_days"][4])
          assert_equal [ { "referrer" => "https://a.example", "clicks" => 2 }, { "referrer" => "https://b.example", "clicks" => 1 } ], body["top_referrers"]
        end
      end

      test "rate limits link creation per client" do
        LinksController::CREATE_LIMIT.times do
          post api_v1_links_url, params: { url: "https://example.com" }, as: :json
          assert_response :created
        end
        post api_v1_links_url, params: { url: "https://example.com" }, as: :json
        assert_response :too_many_requests
      end
    end
  end
end
