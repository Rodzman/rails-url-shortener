require "test_helper"

class ClickTest < ActiveSupport::TestCase
  test "visitor hash is stable for the same visitor on the same day and differs otherwise" do
    a = Click.visitor_hash(ip: "203.0.113.9", user_agent: "UA")
    assert_equal a, Click.visitor_hash(ip: "203.0.113.9", user_agent: "UA")
    assert_not_equal a, Click.visitor_hash(ip: "203.0.113.10", user_agent: "UA")
    travel 1.day do
      assert_not_equal a, Click.visitor_hash(ip: "203.0.113.9", user_agent: "UA")
    end
  end

  test "does not contain the raw ip" do
    assert_no_match(/203\.0\.113\.9/, Click.visitor_hash(ip: "203.0.113.9", user_agent: "UA"))
  end
end
