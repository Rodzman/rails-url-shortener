# Plain-Ruby presenter for the public shape of a Link.
class LinkSerializer
  def initialize(link, base_url:)
    @link = link
    @base_url = base_url
  end

  def as_json(*)
    {
      slug: @link.slug,
      short_url: "#{@base_url}/#{@link.slug}",
      original_url: @link.original_url,
      clicks_count: @link.clicks_count,
      expires_at: @link.expires_at&.iso8601,
      created_at: @link.created_at.iso8601
    }
  end
end
