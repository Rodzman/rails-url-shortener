class Click < ApplicationRecord
  belongs_to :link, counter_cache: true

  # A privacy-preserving visitor identifier: hashed with a daily-rotating salt
  # so we can count unique visitors per day without storing IP addresses.
  def self.visitor_hash(ip:, user_agent:)
    salt = Rails.application.secret_key_base
    Digest::SHA256.hexdigest("#{salt}|#{Date.current}|#{ip}|#{user_agent}").first(32)
  end
end
