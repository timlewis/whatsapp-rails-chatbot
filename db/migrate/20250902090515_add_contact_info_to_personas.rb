class AddContactInfoToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :phone_number, :string
    add_column :personas, :email, :string
  end
end
