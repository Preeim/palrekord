require "fileutils"
require "uri"

class Attachment < ApplicationRecord
  FILE_TYPES = %w[IMAGE PDF TEXT LINK].freeze
  FILE_TYPE_LABELS = {
    "IMAGE" => "📷 Fotó / Képernyőkép",
    "LINK" => "🎬 Videó / Külső Link",
    "TEXT" => "🤝 Tanú / Jegyzőkönyv",
    "PDF" => "📄 PDF Dokumentum"
  }.freeze
  FILE_TYPE_SHORT_LABELS = {
    "IMAGE" => "📷 Fotó",
    "LINK" => "🎬 Videó / Link",
    "TEXT" => "🤝 Jegyzőkönyv",
    "PDF" => "📄 PDF"
  }.freeze
  DEFAULT_TEXT_TEMPLATE = "Jelenlévő tanú(k): \nHelyszín és időpont: \nMérés módja / eszköz: ".freeze
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_IMAGE_EXTS = %w[.png .jpg .jpeg .gif .webp].freeze
  ALLOWED_PDF_EXTS = %w[.pdf].freeze

  belongs_to :record

  attr_accessor :uploaded_file

  before_validation :infer_file_type_from_payload
  before_validation :sanitize_inactive_payload_fields
  before_validation :set_uploaded_at
  before_validation :prepare_uploaded_file
  before_save :track_replaced_file
  before_save :persist_uploaded_file

  validates :file_type, presence: true, inclusion: { in: FILE_TYPES }
  validates :uploaded_at, presence: true
  validate :validate_payload_by_type

  after_save_commit :finalize_persisted_files
  after_rollback :cleanup_newly_persisted_file
  after_destroy_commit :cleanup_stored_file

  def self.storage_root
    if Rails.env.test?
      Rails.root.join("tmp", "storage", "uploads")
    else
      Rails.root.join("storage", "uploads")
    end
  end

  def stored_file_pathname
    return nil unless %w[IMAGE PDF].include?(file_type) && file_path_or_url.present?

    candidate = self.class.storage_root.join(File.basename(file_path_or_url))
    candidate.exist? ? candidate : nil
  end

  def image?
    file_type == "IMAGE"
  end

  def pdf?
    file_type == "PDF"
  end

  def text?
    file_type == "TEXT"
  end

  def link?
    file_type == "LINK"
  end

  def file_attachment?
    %w[IMAGE PDF].include?(file_type)
  end

  def type_label
    FILE_TYPE_LABELS.fetch(file_type, file_type.to_s)
  end

  def short_type_label
    FILE_TYPE_SHORT_LABELS.fetch(file_type, file_type.to_s)
  end

  private

  def infer_file_type_from_payload
    self.file_type = file_type.to_s.strip.upcase.presence
    return if file_type.present?

    if uploaded_file.present? && uploaded_file.respond_to?(:original_filename)
      ext = File.extname(uploaded_file.original_filename.to_s).downcase
      self.file_type = ext == ".pdf" ? "PDF" : "IMAGE"
    elsif file_path_or_url.present?
      self.file_type = "LINK"
    elsif text_content.present?
      self.file_type = "TEXT"
    end
  end

  def sanitize_inactive_payload_fields
    case file_type
    when "IMAGE", "PDF"
      self.text_content = nil
      if new_record? || uploaded_file.present?
        self.file_path_or_url = nil
      elsif %w[IMAGE PDF].include?(file_type_in_database) && file_path_or_url_in_database.to_s.start_with?("uploads/")
        self.file_path_or_url = file_path_or_url_in_database
      else
        self.file_path_or_url = nil
      end
    when "LINK"
      self.file_path_or_url = file_path_or_url.to_s.strip.presence
      self.text_content = nil
      self.uploaded_file = nil
      self.original_filename = nil
    when "TEXT"
      self.text_content = text_content.to_s.strip.presence
      self.file_path_or_url = nil
      self.uploaded_file = nil
      self.original_filename = nil
    end
  end

  def set_uploaded_at
    self.uploaded_at ||= Time.current
  end

  def prepare_uploaded_file
    return unless uploaded_file.present? && uploaded_file.respond_to?(:original_filename)

    orig_name = File.basename(uploaded_file.original_filename.to_s)
    ext = File.extname(orig_name).downcase

    if uploaded_file.respond_to?(:size) && uploaded_file.size > MAX_FILE_SIZE
      errors.add(:uploaded_file, "mérete legfeljebb 10 MB lehet")
      return
    end

    if file_type == "IMAGE" && !ALLOWED_IMAGE_EXTS.include?(ext)
      errors.add(:uploaded_file, "csak PNG, JPG, JPEG, GIF vagy WEBP kép lehet")
      return
    elsif file_type == "PDF" && !ALLOWED_PDF_EXTS.include?(ext)
      errors.add(:uploaded_file, "csak PDF fájl lehet")
      return
    elsif !file_attachment?
      return
    end

    stored_filename = "#{SecureRandom.uuid}#{ext}"
    self.original_filename = orig_name.truncate(255)
    self.file_path_or_url = "uploads/#{stored_filename}"
  end

  def track_replaced_file
    @replaced_file_path = nil
    return if new_record?

    if %w[IMAGE PDF].include?(file_type_in_database) &&
       file_path_or_url_in_database.present? &&
       (!file_attachment? || file_path_or_url != file_path_or_url_in_database)
      @replaced_file_path = self.class.storage_root.join(File.basename(file_path_or_url_in_database))
    end
  end

  def persist_uploaded_file
    @newly_persisted_file_path = nil
    return unless uploaded_file.present? && file_attachment? && file_path_or_url.present?

    FileUtils.mkdir_p(self.class.storage_root)
    destination = self.class.storage_root.join(File.basename(file_path_or_url))

    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    File.binwrite(destination, uploaded_file.read)
    @newly_persisted_file_path = destination
    self.uploaded_file = nil
  end

  def finalize_persisted_files
    if @replaced_file_path.present? && @replaced_file_path != @newly_persisted_file_path && @replaced_file_path.exist?
      File.delete(@replaced_file_path)
    end
  rescue StandardError
    nil
  ensure
    @replaced_file_path = nil
    @newly_persisted_file_path = nil
  end

  def cleanup_newly_persisted_file
    if @newly_persisted_file_path.present? && @newly_persisted_file_path.exist?
      File.delete(@newly_persisted_file_path)
    end
  rescue StandardError
    nil
  ensure
    @newly_persisted_file_path = nil
    @replaced_file_path = nil
  end

  def validate_payload_by_type
    case file_type
    when "TEXT"
      if text_content.blank?
        errors.add(:text_content, "szöveges igazolásnál kötelező")
      end
    when "LINK"
      if file_path_or_url.blank?
        errors.add(:file_path_or_url, "hivatkozásnál kötelező megadni az URL-t")
      elsif !valid_http_url?(file_path_or_url)
        errors.add(:file_path_or_url, "érvényes http:// vagy https:// URL kell legyen")
      end
    when "IMAGE", "PDF"
      if file_path_or_url.blank? && errors[:uploaded_file].blank?
        errors.add(:uploaded_file, "fájl feltöltése kötelező")
      end
    end
  end

  def valid_http_url?(raw_url)
    str = raw_url.to_s
    return false if str.blank? || str.match?(/\s|[[:cntrl:]]/)

    uri = URI.parse(str)
    (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def cleanup_stored_file
    pathname = stored_file_pathname
    File.delete(pathname) if pathname&.exist?
  rescue StandardError
    nil
  end
end
