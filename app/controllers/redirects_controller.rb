class RedirectsController < ApplicationController
  # GET /:slug
  # 302 rather than 301 so browsers keep coming back and every visit is counted.
  def show
    link = Link.find_by(slug: params[:slug])
    return render json: { error: "not found" }, status: :not_found if link.nil?
    return render json: { error: "link expired" }, status: :gone if link.expired?

    link.record_click!(referrer: request.referer, user_agent: request.user_agent, ip: request.remote_ip)
    redirect_to link.original_url, status: :found, allow_other_host: true
  end
end
