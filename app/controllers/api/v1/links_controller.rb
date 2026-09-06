module Api
  module V1
    class LinksController < ApplicationController
      CREATE_LIMIT = 30

      rate_limit to: CREATE_LIMIT, within: 1.minute, only: :create, store: RATE_LIMIT_STORE,
                 with: -> { render json: { error: "rate limit exceeded, try again later" }, status: :too_many_requests }

      # POST /api/v1/links  { "url": "https://...", "slug": "optional", "expires_at": "optional ISO8601" }
      def create
        link = Link.new(original_url: link_params[:url], slug: link_params[:slug], expires_at: link_params[:expires_at])
        if link.save
          render json: LinkSerializer.new(link, base_url: request.base_url), status: :created
        else
          render json: { errors: link.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/links/:slug
      def show
        render json: LinkSerializer.new(link, base_url: request.base_url)
      end

      # GET /api/v1/links/:slug/stats
      def stats
        render json: LinkStats.new(link)
      end

      private
        def link
          @link ||= Link.find_by!(slug: params[:slug])
        end

        def link_params
          params.permit(:url, :slug, :expires_at)
        end
    end
  end
end
