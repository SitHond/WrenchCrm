# Which requests belong to the public website and which to the CRM.
# SITE_HOST=domain.com serves the site on domain.com and www.domain.com; without it the site
# is previewed at /site on the CRM host.
module SiteHost
  module_function

  def host = ENV["SITE_HOST"].to_s.strip.downcase.presence

  def configured? = host.present?

  def site_request?(request) = configured? && [ host, "www.#{host}" ].include?(request.host.to_s.downcase)

  def matches?(request) = !configured? || site_request?(request)
end

module CrmHost
  module_function

  def matches?(request) = !SiteHost.site_request?(request)
end
