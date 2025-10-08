ActiveAdmin.register Response do
  menu parent: "Response Data", priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :questionnaire_id, :employee_id, :unique_token, :status, :submitted_at
  #
  # or
  #
  # permit_params do
  #   permitted = [:questionnaire_id, :employee_id, :unique_token, :status, :submitted_at]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
