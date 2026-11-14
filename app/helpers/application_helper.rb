module ApplicationHelper
  STATUS_LABELS = {
    "PENDING" => "Függőben",
    "APPROVED" => "Elfogadva",
    "REJECTED" => "Elutasítva"
  }.freeze

  VALUE_TYPE_HINTS = {
    "INT" => "Egész szám (pl. 19)",
    "DOUBLE" => "Tört vagy egész szám (pl. 125.0)",
    "TIME_DURATION" => "Másodperc vagy perc:mp (pl. 18.42 vagy 04:12.00)",
    "DATE" => "Dátum ÉÉÉÉ-HH-NN formátumban (pl. 2026-11-13)"
  }.freeze

  def status_badge(status)
    label = STATUS_LABELS.fetch(status, status)
    css_class = "badge badge-#{status.to_s.downcase}"
    content_tag(:span, label, class: css_class)
  end

  def points_badge(points, rank: nil, archived: false)
    if archived
      content_tag(:span, "0 pt", class: "badge badge-muted")
    elsif rank == 1
      content_tag(:span, "+#{points} pt", class: "badge badge-points-first")
    else
      content_tag(:span, "+#{points} pt", class: "badge badge-points")
    end
  end

  def value_type_hint(value_type)
    VALUE_TYPE_HINTS[value_type] || ""
  end

  def attachment_type_badge(attachment)
    return nil if attachment.blank? || attachment.file_type.blank?

    content_tag(:span, attachment.short_type_label, class: "badge badge-proof")
  end

  def recommended_proof_badge(file_type)
    label = Attachment::FILE_TYPE_LABELS[file_type]
    return nil if label.blank?

    content_tag(:span, label, class: "badge badge-proof")
  end
end
