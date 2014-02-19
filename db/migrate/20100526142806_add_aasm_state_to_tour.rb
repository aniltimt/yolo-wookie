class AddAasmStateToTour < ActiveRecord::Migration
  def self.up
    add_column :tours, :aasm_state, :string
  end

  def self.down
    remove_column :tours, :aasm_state, :string
  end
end
