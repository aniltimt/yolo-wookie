class AddAttachmentHashToMedia < ActiveRecord::Migration
  def self.up
    add_column :media, :attachment_hash, :string
  end

  def self.down
    remove_column :media, :attachment_hash
  end
end
