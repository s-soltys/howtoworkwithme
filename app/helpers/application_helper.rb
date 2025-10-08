module ApplicationHelper
  def alert_class(type)
    case type.to_sym
    when :notice
      "alert-success"
    when :success
      "alert-success"
    when :error
      "alert-error"
    when :alert
      "alert-warning"
    when :warning
      "alert-warning"
    else
      "alert-info"
    end
  end
end
