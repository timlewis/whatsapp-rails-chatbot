class CreatePersonas < ActiveRecord::Migration[8.0]
  def change
    create_table :personas do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.text :base_prompt, null: false
      t.boolean :config_default, default: false, null: false

      t.timestamps
    end
    add_index :personas, :config_default, unique: true, where: "config_default = true"
  end
end
