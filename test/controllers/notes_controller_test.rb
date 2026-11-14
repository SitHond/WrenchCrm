require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  test "private notes are visible only to their author" do
    sign_in_as users(:editor)
    get person_path(people(:guest))
    assert_match "Публичная заметка", response.body
    assert_no_match "Секретная заметка", response.body

    sign_in_as users(:admin)
    get person_path(people(:guest))
    assert_match "Секретная заметка", response.body
  end

  test "editor adds a note" do
    sign_in_as users(:editor)
    assert_difference(-> { people(:sergey).notes.count }) do
      post person_notes_path(people(:sergey)), params: { note: { body: "Позвонить" } }
    end
    assert_equal users(:editor), Note.last.author
  end

  test "cannot edit someone else's note" do
    sign_in_as users(:editor)
    patch note_path(notes(:private_note)), params: { note: { body: "Взлом" } }
    assert_equal "Секретная заметка", notes(:private_note).reload.body
  end

  test "viewer without notes permission cannot add notes" do
    sign_in_as users(:viewer)
    assert_no_difference(-> { Note.count }) do
      post person_notes_path(people(:sergey)), params: { note: { body: "x" } }
    end
  end
end
