require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  test "private notes are visible only to their author" do
    sign_in_as users(:advisor)
    get client_path(clients(:petrov))
    assert_match "Публичная заметка", response.body
    assert_no_match "Секретная заметка", response.body

    sign_in_as users(:admin)
    get client_path(clients(:petrov))
    assert_match "Секретная заметка", response.body
  end

  test "adds notes to vehicles and work orders" do
    sign_in_as users(:viewer)
    assert_difference(-> { Note.count }, 2) do
      post vehicle_notes_path(vehicles(:solaris)), params: { note: { body: "Царапина на бампере" } }
      post work_order_notes_path(work_orders(:open_order)), params: { note: { body: "Клиент ждёт звонка" } }
    end
  end

  test "cannot edit someone else's note" do
    sign_in_as users(:advisor)
    patch note_path(notes(:private_note)), params: { note: { body: "Взлом" } }
    assert_equal "Секретная заметка", notes(:private_note).reload.body
  end
end
