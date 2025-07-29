
class ChangeArgumentsTypeInToolCalls < ActiveRecord::Migration[8.0]
  def change
    # Change column type from string to json
    remove_column :tool_calls, :arguments, :string
    add_column :tool_calls, :arguments, :json, null: false, default: {}
  end
end
