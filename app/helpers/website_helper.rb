module WebsiteHelper
  def website_public_url
    SiteHost.configured? ? site_root_url(host: SiteHost.host) : site_root_path
  end

  def website_label(record)
    record.try(:title) || record.try(:author)
  end

  def website_visible?(record)
    case record
    when SitePage, SiteReview then record.published?
    else record.active? && (record.starts_on.nil? || record.starts_on <= Date.current) && (record.ends_on.nil? || record.ends_on >= Date.current)
    end
  end

  def website_period(record)
    return unless record.respond_to?(:starts_on)

    [ (l(record.starts_on) if record.starts_on), (l(record.ends_on) if record.ends_on) ].compact.join(" — ")
  end
end
