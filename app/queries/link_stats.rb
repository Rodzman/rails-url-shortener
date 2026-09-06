# Aggregates click data for one link. Grouping by day is done in Ruby so the
# query stays portable across SQLite, PostgreSQL and MySQL.
class LinkStats
  DAYS = 7
  TOP_REFERRERS = 5

  def initialize(link)
    @link = link
  end

  def as_json(*)
    {
      slug: @link.slug,
      total_clicks: @link.clicks_count,
      unique_visitors_today: unique_visitors_today,
      last_7_days: last_days,
      top_referrers: top_referrers
    }
  end

  private
    def window_start
      (DAYS - 1).days.ago.beginning_of_day
    end

    def last_days
      per_day = @link.clicks.where(created_at: window_start..).pluck(:created_at)
                     .group_by { |t| t.to_date }.transform_values(&:size)
      (0...DAYS).map do |i|
        date = (window_start + i.days).to_date
        { date: date.iso8601, clicks: per_day.fetch(date, 0) }
      end
    end

    def unique_visitors_today
      @link.clicks.where(created_at: Time.current.all_day).distinct.count(:visitor_hash)
    end

    def top_referrers
      @link.clicks.where.not(referrer: [ nil, "" ])
           .group(:referrer).order(count_all: :desc).limit(TOP_REFERRERS).count
           .map { |referrer, clicks| { referrer: referrer, clicks: clicks } }
    end
end
