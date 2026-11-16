require "test_helper"
require "tempfile"
require "fileutils"

class AttachmentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      username: "attuser",
      display_name: "Melléklet Teszt",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    @category = Category.create!(name: "Teszt szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    @record = Record.create!(user: @user, category: @category, value: "15", achieved_at: Date.current)
  end

  teardown do
    FileUtils.rm_rf(Attachment.storage_root)
  end

  test "validates TEXT and LINK payloads strictly" do
    empty_text = Attachment.new(record: @record, file_type: "TEXT", text_content: "")
    assert_not empty_text.valid?
    assert empty_text.errors[:text_content].present?

    valid_text = Attachment.create!(record: @record, file_type: "TEXT", text_content: "Két tanú látta")
    assert valid_text.text?
    assert_not valid_text.file_attachment?

    invalid_link = Attachment.new(record: @record, file_type: "LINK", file_path_or_url: "javascript:alert(1)")
    assert_not invalid_link.valid?
    assert invalid_link.errors[:file_path_or_url].present?

    xss_with_https = Attachment.new(record: @record, file_type: "LINK", file_path_or_url: "javascript:alert('https://example.com')")
    assert_not xss_with_https.valid?
    assert xss_with_https.errors[:file_path_or_url].present?

    missing_host_link = Attachment.new(record: @record, file_type: "LINK", file_path_or_url: "https://")
    assert_not missing_host_link.valid?
    assert missing_host_link.errors[:file_path_or_url].present?

    tampered_upload = Attachment.new(record: @record, file_type: "IMAGE", file_path_or_url: "uploads/other.png")
    assert_not tampered_upload.valid?
    assert tampered_upload.errors[:uploaded_file].present?

    valid_link = Attachment.create!(record: @record, file_type: "LINK", file_path_or_url: "https://example.com/video")
    assert valid_link.link?

    assert_not valid_link.update(file_type: "IMAGE", file_path_or_url: "uploads/other.png")
    assert valid_link.errors[:uploaded_file].present?
  end

  test "validates IMAGE and PDF extensions and max file size" do
    bad_ext = build_uploaded_file("malware.exe", "binary")
    att_bad_ext = Attachment.new(record: @record, file_type: "IMAGE", uploaded_file: bad_ext)
    assert_not att_bad_ext.valid?
    assert att_bad_ext.errors[:uploaded_file].present?

    wrong_pdf = build_uploaded_file("photo.png", "pngbytes")
    att_wrong_pdf = Attachment.new(record: @record, file_type: "PDF", uploaded_file: wrong_pdf)
    assert_not att_wrong_pdf.valid?
    assert att_wrong_pdf.errors[:uploaded_file].present?

    oversized = Struct.new(:original_filename, :size).new("huge.png", Attachment::MAX_FILE_SIZE + 1)
    att_huge = Attachment.new(record: @record, file_type: "IMAGE", uploaded_file: oversized)
    assert_not att_huge.valid?
    assert att_huge.errors[:uploaded_file].present?
  end

  test "persists uploaded IMAGE and PDF files into test storage_root" do
    png_file = build_uploaded_file("proof.png", "\x89PNG\r\n\x1a\n")
    image_att = Attachment.create!(record: @record, file_type: "IMAGE", uploaded_file: png_file)

    assert image_att.file_attachment?
    assert_equal "proof.png", image_att.original_filename
    assert_not_nil image_att.stored_file_pathname
    assert image_att.stored_file_pathname.exist?

    pdf_file = build_uploaded_file("diploma.pdf", "%PDF-1.4")
    pdf_att = Attachment.create!(record: @record, file_type: "PDF", uploaded_file: pdf_file)
    assert_not_nil pdf_att.stored_file_pathname
    assert pdf_att.stored_file_pathname.exist?
  end

  test "infers file_type automatically when blank and cleans inactive fields" do
    png_file = build_uploaded_file("auto.png", "\x89PNG\r\n\x1a\n")
    inferred_img = Attachment.create!(record: @record, file_type: "", uploaded_file: png_file, text_content: "ignored")
    assert_equal "IMAGE", inferred_img.file_type
    assert_nil inferred_img.text_content
    assert_equal "📷 Fotó / Képernyőkép", inferred_img.type_label
    assert_equal "📷 Fotó", inferred_img.short_type_label

    pdf_file = build_uploaded_file("auto.pdf", "%PDF-1.4")
    inferred_pdf = Attachment.create!(record: @record, file_type: nil, uploaded_file: pdf_file)
    assert_equal "PDF", inferred_pdf.file_type
    assert inferred_pdf.pdf?

    inferred_link = Attachment.create!(record: @record, file_type: "", file_path_or_url: "  https://example.com/run  ", text_content: "ignored")
    assert_equal "LINK", inferred_link.file_type
    assert_equal "https://example.com/run", inferred_link.file_path_or_url
    assert_nil inferred_link.text_content

    inferred_text = Attachment.create!(record: @record, file_type: "", text_content: "Tanúk: Peti, Anna")
    assert_equal "TEXT", inferred_text.file_type
    assert_nil inferred_text.file_path_or_url

    cleaned_text = Attachment.create!(record: @record, file_type: "TEXT", text_content: "Tanúk: Peti, Anna", file_path_or_url: "https://ignored.example")
    assert_equal "TEXT", cleaned_text.file_type
    assert_nil cleaned_text.file_path_or_url
  end

  private

  def build_uploaded_file(filename, content)
    tmp = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
    tmp.binmode
    tmp.write(content)
    tmp.rewind
    Rack::Test::UploadedFile.new(tmp.path, "application/octet-stream", original_filename: filename)
  end
end

class AttachmentCleanupCommitTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  teardown do
    Attachment.destroy_all
    Record.destroy_all
    Category.destroy_all
    User.destroy_all
    FileUtils.rm_rf(Attachment.storage_root)
  end

  test "cleanup_stored_file removes physical file on destroy commit" do
    user = User.create!(
      username: "cleanuser",
      display_name: "Törlő Teszt",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    category = Category.create!(name: "Cleanup szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    record = Record.create!(user: user, category: category, value: "5", achieved_at: Date.current)

    tmp = Tempfile.new([ "cleanup", ".png" ])
    tmp.binmode
    tmp.write("pngdata")
    tmp.rewind
    uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/png", original_filename: "cleanup.png")

    att = Attachment.create!(record: record, file_type: "IMAGE", uploaded_file: uploaded)
    stored_path = att.stored_file_pathname
    assert stored_path.exist?

    att.destroy!
    assert_not stored_path.exist?
  end

  test "removes replaced physical file on update commit and cleans up on rollback" do
    user = User.create!(
      username: "replaceuser",
      display_name: "Csere Teszt",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    category = Category.create!(name: "Csere szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    record = Record.create!(user: user, category: category, value: "7", achieved_at: Date.current)

    tmp1 = Tempfile.new([ "first", ".png" ])
    tmp1.binmode
    tmp1.write("png1")
    tmp1.rewind
    att = Attachment.create!(
      record: record,
      file_type: "IMAGE",
      uploaded_file: Rack::Test::UploadedFile.new(tmp1.path, "image/png", original_filename: "first.png")
    )
    first_path = att.stored_file_pathname
    assert first_path.exist?

    # Replacing IMAGE with a new IMAGE deletes the old file after commit
    tmp2 = Tempfile.new([ "second", ".png" ])
    tmp2.binmode
    tmp2.write("png2")
    tmp2.rewind
    att.update!(
      file_type: "IMAGE",
      uploaded_file: Rack::Test::UploadedFile.new(tmp2.path, "image/png", original_filename: "second.png")
    )
    second_path = att.stored_file_pathname
    assert second_path.exist?
    assert_not_equal first_path, second_path
    assert_not first_path.exist?

    # Switching IMAGE to LINK deletes the stored physical file after commit
    att.update!(file_type: "LINK", file_path_or_url: "https://example.com/proof")
    assert_not second_path.exist?

    # Rolling back an attachment creation removes the newly written file
    tmp3 = Tempfile.new([ "rollback", ".png" ])
    tmp3.binmode
    tmp3.write("png3")
    tmp3.rewind
    rollback_path = nil
    ActiveRecord::Base.transaction do
      rolled = Attachment.create!(
        record: record,
        file_type: "IMAGE",
        uploaded_file: Rack::Test::UploadedFile.new(tmp3.path, "image/png", original_filename: "rollback.png")
      )
      rollback_path = rolled.stored_file_pathname
      assert rollback_path.exist?
      raise ActiveRecord::Rollback
    end
    assert_not rollback_path.exist?
  ensure
    [ tmp1, tmp2, tmp3 ].compact.each(&:close!)
  end
end
