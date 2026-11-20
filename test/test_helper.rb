ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Customer approval for lines added after work started (ПП № 290).
    def approve_all(order)
      (order.labor_lines.reload + order.part_lines.reload).each { |line| line.approve!(method: :in_person) unless line.approved? }
    end
  end
end
