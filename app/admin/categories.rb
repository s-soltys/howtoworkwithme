ActiveAdmin.register Category do
  permit_params :name, :position, :questionnaire_id

  index do
    selectable_column
    id_column
    column :name
    column :questionnaire
    column :position
    column :created_at
    actions
  end

  filter :name
  filter :questionnaire
  filter :position

  form do |f|
    f.inputs do
      f.input :questionnaire
      f.input :name
      f.input :position
    end
    f.actions
  end
end
