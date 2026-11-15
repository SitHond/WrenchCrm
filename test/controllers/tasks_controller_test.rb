require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:viewer) }

  test "create on a client, complete, see the badge" do
    post tasks_path, params: { task: { title: "Перезвонить по смете", due_on: Date.current, subject_type: "Client", subject_id: clients(:petrov).id } }
    task = Task.last
    assert_equal clients(:petrov), task.subject
    get root_path
    assert_select ".nav-badge", text: "1"
    get client_path(clients(:petrov))
    assert_match "Перезвонить по смете", response.body
    patch toggle_task_path(task)
    assert task.reload.done?
  end

  test "subject type is whitelisted" do
    post tasks_path, params: { task: { title: "X", subject_type: "User", subject_id: users(:admin).id } }
    assert_nil Task.last.subject
  end

  test "index filters" do
    Task.create!(title: "Моя", assignee: users(:viewer))
    Task.create!(title: "Чужая", assignee: users(:admin))
    get tasks_path
    assert_match "Моя", response.body
    assert_no_match "Чужая", response.body
    get tasks_path(who: "all")
    assert_match "Чужая", response.body
  end
end
