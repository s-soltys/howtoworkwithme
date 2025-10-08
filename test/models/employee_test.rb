require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    org = Organization.create!(name: "Acme")
    employee = org.employees.build(name: "Alice")
    assert employee.valid?
  end

  test "should require name" do
    org = Organization.create!(name: "Acme")
    employee = org.employees.build(name: nil)
    assert_not employee.valid?
    assert_includes employee.errors[:name], "can't be blank"
  end

  test "should require organization" do
    employee = Employee.new(name: "Alice")
    assert_not employee.valid?
  end

  test "should have many responses" do
    org = Organization.create!(name: "Acme")
    employee = org.employees.create!(name: "Alice")
    quest = org.questionnaires.create!(title: "Survey")
    resp1 = employee.responses.create!(questionnaire: quest)
    resp2 = employee.responses.create!(questionnaire: quest)

    assert_equal 2, employee.responses.count
  end
end
