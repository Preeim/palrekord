require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "status_badge renders Hungarian labels and status classes" do
    pending_html = status_badge("PENDING")
    assert_includes pending_html, "badge badge-pending"
    assert_includes pending_html, "Függőben"

    approved_html = status_badge("APPROVED")
    assert_includes approved_html, "badge badge-approved"
    assert_includes approved_html, "Elfogadva"

    rejected_html = status_badge("REJECTED")
    assert_includes rejected_html, "badge badge-rejected"
    assert_includes rejected_html, "Elutasítva"
  end

  test "points_badge highlights first place, standard placements, and archived categories" do
    first_html = points_badge(12, rank: 1)
    assert_includes first_html, "badge-points-first"
    assert_includes first_html, "+12 pt"

    second_html = points_badge(8, rank: 2)
    assert_includes second_html, "badge-points"
    assert_includes second_html, "+8 pt"

    archived_html = points_badge(0, rank: 1, archived: true)
    assert_includes archived_html, "badge-muted"
    assert_includes archived_html, "0 pt"
  end

  test "value_type_hint returns hints for all supported category value types" do
    assert_includes value_type_hint("INT"), "Egész szám"
    assert_includes value_type_hint("DOUBLE"), "Tört vagy egész szám"
    assert_includes value_type_hint("TIME_DURATION"), "Másodperc"
    assert_includes value_type_hint("DATE"), "ÉÉÉÉ-HH-NN"
    assert_equal "", value_type_hint("UNKNOWN")
  end
end
