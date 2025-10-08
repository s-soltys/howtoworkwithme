require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  # Validations
  test "should be valid with valid attributes" do
    organization = Organization.new(name: "Acme Corp")
    assert organization.valid?
  end

  test "should require name" do
    organization = Organization.new(name: nil)
    assert_not organization.valid?
    assert_includes organization.errors[:name], "can't be blank"
  end

  test "should generate unique_token automatically" do
    organization = Organization.create!(name: "Acme Corp")
    assert_not_nil organization.unique_token
    assert_equal 36, organization.unique_token.length
  end

  test "should have unique unique_token" do
    org1 = Organization.create!(name: "Acme Corp")
    org2 = Organization.new(name: "Beta Inc", unique_token: org1.unique_token)
    assert_not org2.valid?
    assert_includes org2.errors[:unique_token], "has already been taken"
  end

  # Associations
  test "should have many questionnaires" do
    organization = Organization.create!(name: "Acme Corp")
    questionnaire1 = organization.questionnaires.create!(title: "Survey 1")
    questionnaire2 = organization.questionnaires.create!(title: "Survey 2")

    assert_equal 2, organization.questionnaires.count
    assert_includes organization.questionnaires, questionnaire1
    assert_includes organization.questionnaires, questionnaire2
  end

  test "should have many employees" do
    organization = Organization.create!(name: "Acme Corp")
    employee1 = organization.employees.create!(name: "Alice")
    employee2 = organization.employees.create!(name: "Bob")

    assert_equal 2, organization.employees.count
    assert_includes organization.employees, employee1
    assert_includes organization.employees, employee2
  end

  test "should destroy dependent questionnaires when destroyed" do
    organization = Organization.create!(name: "Acme Corp")
    questionnaire = organization.questionnaires.create!(title: "Survey")

    assert_difference "Questionnaire.count", -1 do
      organization.destroy
    end
  end

  test "should destroy dependent employees when destroyed" do
    organization = Organization.create!(name: "Acme Corp")
    employee = organization.employees.create!(name: "Alice")

    assert_difference "Employee.count", -1 do
      organization.destroy
    end
  end
end
