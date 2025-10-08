ActiveAdmin.register Questionnaire do
  permit_params :title, :description, :active, :locked_at, :organization_id

  index do
    selectable_column
    id_column
    column :title
    column :organization
    column :active
    column :locked_at
    column :unique_token
    column :created_at
    actions
  end

  filter :title
  filter :organization
  filter :active
  filter :locked_at
  filter :created_at

  form do |f|
    f.inputs do
      f.input :organization
      f.input :title
      f.input :description
      f.input :active
      f.input :locked_at, as: :datepicker
    end
    f.actions
  end
end
