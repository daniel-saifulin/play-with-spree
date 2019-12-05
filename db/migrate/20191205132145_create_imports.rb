class CreateImports < ActiveRecord::Migration[5.1]
  def change
    create_table :imports do |t|
      t.integer :attachment_id, null: false
      t.integer :status, default: 0
      t.json :data, default: {}

      t.timestamps
    end
  end
end
