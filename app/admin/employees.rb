ActiveAdmin.register Employee do
  menu parent: "Organization Management", priority: 2

  permit_params :name, :email, :organization_id

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :organization
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :organization

  form do |f|
    f.inputs do
      f.input :organization
      f.input :name
      f.input :email
    end
    f.actions
  end
end
