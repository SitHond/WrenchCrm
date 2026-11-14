class DashboardController < ApplicationController
  def show
    @people_count = Person.active.count
    @families_count = Family.active.count
    @groups_count = Group.active.count
    @members_count = Person.active.member.count
    @birthdays = Person.active.with_birthday_in(Date.current.month).limit(20)
    @recent_people = Person.order(created_at: :desc).limit(8)
    @classification_counts = Person.active.group(:classification).count
  end
end
