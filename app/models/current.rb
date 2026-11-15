class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # Set while loading historical data: no stock moves, reminders or editability checks.
  attribute :importing
  delegate :user, to: :session, allow_nil: true
end
