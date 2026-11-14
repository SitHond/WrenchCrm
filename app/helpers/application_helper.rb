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

  def classification_badge(person)
    tag.span(enum_label(Person, :classification, person.classification), class: "badge badge-#{person.classification}")
  end

  def detail_row(label, value)
    return if value.blank?

    safe_join([ tag.dt(label), tag.dd(value) ])
  end

  def birthday_text(person)
    return unless person.birth_month && person.birth_day

    date = Date.new(person.birth_year || 2000, person.birth_month, person.birth_day)
    text = l(date, format: person.birth_year ? :long : :day_month)
    person.age ? "#{text} (#{t('people.age', count: person.age)})" : text
  end

  def can?(permission)
    permission == :admin ? current_user&.admin? : current_user&.public_send(:"can_#{permission}?")
  end

  def pagination(pagy)
    render "shared/pagination", pagy: pagy if pagy.pages > 1
  end
end
