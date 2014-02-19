class ReplaceAttachmentHashWithFingerprintsInMedium < ActiveRecord::Migration
  def self.up
    rename_column :media, :attachment_hash, :attachment_fingerprint
  end

  def self.down
    rename_column :media, :attachment_fingerprint, :attachment_hash
  end
end
