module ApplicationHelper
  def flash_class_for(flash_type)
    case flash_type.to_sym
    when :notice
      'bg-green-50 border border-green-200 text-green-800'
    when :alert
      'bg-red-50 border border-red-200 text-red-800'
    when :error
      'bg-red-50 border border-red-200 text-red-800'
    else
      'bg-blue-50 border border-blue-200 text-blue-800'
    end
  end
end
