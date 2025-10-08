ActiveAdmin.register Profile do
  menu parent: "Response Data", priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :response_id, :unique_token, :viewed_count
  #
  # or
  #
  # permit_params do
  #   permitted = [:response_id, :unique_token, :viewed_count]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
