class Link < ApplicationRecord
  # Unanchored for use as a route constraint; anchored for validation.
  SLUG_PATTERN = /[a-zA-Z0-9_-]{3,32}/
  SLUG_FORMAT = /\A#{SLUG_PATTERN.source}\z/
  RESERVED_SLUGS = %w[ api up health assets ].freeze
  GENERATED_SLUG_LENGTH = 7
  GENERATION_ATTEMPTS = 5

  has_many :clicks, dependent: :destroy

  before_validation :generate_slug, on: :create, if: -> { slug.blank? }

  validates :original_url, presence: true, length: { maximum: 2048 }
  validates :slug, presence: true,
                   format: { with: SLUG_FORMAT, message: "must be 3-32 characters using letters, numbers, - or _" },
                   exclusion: { in: RESERVED_SLUGS, message: "is reserved" },
                   uniqueness: { case_sensitive: false }
  validate :original_url_must_be_http
  validate :expires_at_must_be_in_the_future, on: :create

  scope :active, -> { where(expires_at: nil).or(where(expires_at: Time.current..)) }

  def to_param = slug

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Records one visit. `clicks_count` is maintained by the counter cache on Click.
  def record_click!(referrer:, user_agent:, ip:)
    clicks.create!(
      referrer: referrer&.first(2048),
      user_agent: user_agent&.first(512),
      visitor_hash: Click.visitor_hash(ip: ip, user_agent: user_agent)
    )
  end

  private
    def generate_slug
      GENERATION_ATTEMPTS.times do
        candidate = SecureRandom.alphanumeric(GENERATED_SLUG_LENGTH)
        next if RESERVED_SLUGS.include?(candidate) || Link.exists?(slug: candidate)

        self.slug = candidate
        return
      end
      errors.add(:slug, "could not be generated, please retry")
    end

    def original_url_must_be_http
      return if original_url.blank?

      uri = URI.parse(original_url)
      unless uri.is_a?(URI::HTTP) && uri.host.present?
        errors.add(:original_url, "must be an http or https URL with a host")
      end
    rescue URI::InvalidURIError
      errors.add(:original_url, "is not a valid URL")
    end

    def expires_at_must_be_in_the_future
      if expires_at.present? && expires_at <= Time.current
        errors.add(:expires_at, "must be in the future")
      end
    end
end
