ActiveAdmin.register QuestionOption do
  menu parent: "Questionnaire Setup", priority: 4

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :question_id, :text, :position
  #
  # or
  #
  # permit_params do
  #   permitted = [:question_id, :text, :position]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
