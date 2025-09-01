class CreateFaqs < ActiveRecord::Migration[8.0]
  def change
    create_table :faqs do |t|
      t.text :question, null: false
      t.text :answer, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :faqs, :active
  end
end
