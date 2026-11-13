require "fileutils"

class Attachment < ApplicationRecord
  FILE_TYPES = %w[IMAGE PDF TEXT LINK].freeze
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_IMAGE_EXTS = %w[.png .jpg .jpeg .gif .webp].freeze
  ALLOWED_PDF_EXTS = %w[.pdf].freeze

  belongs_to :record

  attr_accessor :uploaded_file

  before_validation :set_uploaded_at
  before_validation :prepare_uploaded_file
  before_save :persist_uploaded_file

  validates :file_type, presence: true, inclusion: { in: FILE_TYPES }
  validates :uploaded_at, presence: true
  validate :validate_payload_by_type

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

  def text?
    file_type == "TEXT"
  end

  def link?
    file_type == "LINK"
  end

  def file_attachment?
    %w[IMAGE PDF].include?(file_type)
  end

  private

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

  def persist_uploaded_file
    return unless uploaded_file.present? && file_attachment? && file_path_or_url.present?

    FileUtils.mkdir_p(self.class.storage_root)
    destination = self.class.storage_root.join(File.basename(file_path_or_url))

    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    File.binwrite(destination, uploaded_file.read)
    self.uploaded_file = nil
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
      elsif !file_path_or_url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
        errors.add(:file_path_or_url, "érvényes http:// vagy https:// URL kell legyen")
      end
    when "IMAGE", "PDF"
      if file_path_or_url.blank? && errors[:uploaded_file].blank?
        errors.add(:uploaded_file, "fájl feltöltése kötelező")
      end
    end
  end

  def cleanup_stored_file
    pathname = stored_file_pathname
    File.delete(pathname) if pathname&.exist?
  rescue StandardError
    nil
  end
end
