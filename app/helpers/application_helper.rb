module ApplicationHelper
  include Pagy::Frontend

  def enum_label(model_class, attribute, value)
    return if value.blank?

    t("activerecord.enums.#{model_class.model_name.i18n_key}.#{attribute}.#{value}")
  end

  def enum_options(model_class, attribute)
    model_class.public_send(attribute.to_s.pluralize).keys.map { |key| [ enum_label(model_class, attribute, key), key ] }
  end

  def nav_link(label, path, active_prefix: path)
    active = request.path == path || (active_prefix != "/" && request.path.start_with?(active_prefix))
    link_to label, path, class: [ "nav-link", ("active" if active) ]
  end

  def page_header(title, &actions)
    content_for(:title, title)
    tag.div(class: "page-header") do
      safe_join([ tag.h1(title), (tag.div(capture(&actions), class: "actions") if actions) ].compact)
    end
  end

  def detail_row(label, value)
    return if value.blank?

    safe_join([ tag.dt(label), tag.dd(value) ])
  end

  def money(amount)
    number_to_currency(amount || 0, unit: Rails.configuration.x.currency_unit, format: "%n %u", precision: 2)
  end

  def quantity_with_unit(quantity, unit)
    "#{number_with_precision(quantity, precision: 3, strip_insignificant_zeros: true)} #{t("parts.units.#{unit}")}"
  end

  def number(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
  end

  def status_badge(work_order)
    tag.span(enum_label(WorkOrder, :status, work_order.status), class: "badge status-#{work_order.status}")
  end

  def can?(permission)
    permission == :admin ? current_user&.admin? : current_user&.public_send(:"can_#{permission}?")
  end

  def pagination(pagy)
    render "shared/pagination", pagy: pagy if pagy.pages > 1
  end

  def status_filter_options
    [ [ t("status.active"), "active" ], [ t("status.inactive"), "inactive" ] ]
  end
end
