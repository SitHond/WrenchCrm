# "Ноябрь 2026" / "November 2026": Russian needs the nominative month name, which %B does not give.
module MonthLabel
  module_function

  def call(date)
    names = I18n.t("date.standalone_month_names", default: nil) || I18n.t("date.month_names")
    "#{names[date.month]} #{date.year}"
  end
end
