module AppointmentsHelper
  SLOT_MINUTES = 30

  def calendar_slots(date)
    hours = Rails.configuration.x.workday_hours
    start = date.in_time_zone.change(hour: hours.first)
    count = (hours.last - hours.first) * 60 / SLOT_MINUTES
    Array.new(count) { |index| start + (index * SLOT_MINUTES).minutes }
  end

  def calendar_columns(bays, appointments)
    columns = bays.map { |bay| { bay: bay, label: bay.name } }
    columns << { bay: nil, label: t("appointments.no_bay") } if bays.empty? || appointments.any? { |a| a.bay_id.nil? || bays.none? { |b| b.id == a.bay_id } }
    columns
  end

  def calendar_column_index(columns, appointment)
    index = columns.index { |column| column[:bay]&.id == appointment.bay_id }
    index || columns.index { |column| column[:bay].nil? }
  end

  # Grid rows: row 1 is the header, slot N sits in row N + 2.
  def calendar_rows(slots, appointment)
    first = slots.first
    last_end = slots.last + SLOT_MINUTES.minutes
    from = [ appointment.starts_at, first ].max
    to = [ appointment.ends_at, last_end ].min
    return if to <= first || from >= last_end

    start_row = ((from - first) / 60 / SLOT_MINUTES).floor + 2
    span = [ ((to - from) / 60 / SLOT_MINUTES).ceil, 1 ].max
    [ start_row, span ]
  end

  def appointment_time_range(appointment)
    "#{l(appointment.starts_at, format: :time)}–#{l(appointment.ends_at, format: :time)}"
  end
end
