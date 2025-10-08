class OrganizationsController < ApplicationController
  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      redirect_to organization_path(@organization.unique_token), notice: "Organization created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @organization = Organization.find_by!(unique_token: params[:unique_token])
    @questionnaires = @organization.questionnaires.order(created_at: :desc)
  end

  private

  def organization_params
    params.require(:organization).permit(:name)
  end
end
