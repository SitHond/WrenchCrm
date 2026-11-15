require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup { Current.session = users(:advisor).sessions.create! }

  test "defaults the assignee and author to the current user" do
    task = Task.create!(title: "Позвонить")
    assert_equal users(:advisor), task.assignee
    assert_equal users(:advisor), task.created_by
  end

  test "toggle and overdue" do
    task = Task.create!(title: "Заказать", due_on: Date.yesterday)
    assert task.overdue?
    task.toggle!
    assert task.done?
    assert_not task.overdue?
  end

  test "due_by counts open tasks up to the date" do
    Task.create!(title: "Сегодня", due_on: Date.current)
    Task.create!(title: "Завтра", due_on: Date.tomorrow)
    Task.create!(title: "Сделано", due_on: Date.current, done_at: Time.current)
    assert_equal [ "Сегодня" ], Task.due_by(Date.current).pluck(:title)
  end

  test "only author or admin can delete" do
    task = Task.create!(title: "Тест")
    assert task.deletable_by?(users(:advisor))
    assert task.deletable_by?(users(:admin))
    assert_not task.deletable_by?(users(:viewer))
  end
end
