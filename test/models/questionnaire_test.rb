require "test_helper"

class QuestionnaireTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.build(title: "Survey")
    assert questionnaire.valid?
  end

  test "should require title" do
    questionnaire = Questionnaire.new(organization: Organization.create!(name: "Acme"))
    assert_not questionnaire.valid?
    assert_includes questionnaire.errors[:title], "can't be blank"
  end

  test "should require organization" do
    questionnaire = Questionnaire.new(title: "Survey")
    assert_not questionnaire.valid?
  end

  test "should generate unique_token automatically" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")
    assert_not_nil questionnaire.unique_token
    assert_equal 36, questionnaire.unique_token.length
  end

  test "should have active default to true" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")
    assert questionnaire.active?
  end

  test "active scope returns only active questionnaires" do
    org = Organization.create!(name: "Acme")
    active = org.questionnaires.create!(title: "Active", active: true)
    inactive = org.questionnaires.create!(title: "Inactive", active: false)

    assert_includes Questionnaire.active, active
    assert_not_includes Questionnaire.active, inactive
  end

  test "locked scope returns only locked questionnaires" do
    org = Organization.create!(name: "Acme")
    locked = org.questionnaires.create!(title: "Locked", locked_at: Time.current)
    unlocked = org.questionnaires.create!(title: "Unlocked")

    assert_includes Questionnaire.locked, locked
    assert_not_includes Questionnaire.locked, unlocked
  end

  test "locked? returns true when locked_at is set" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")
    assert_not questionnaire.locked?

    questionnaire.update!(locked_at: Time.current)
    assert questionnaire.locked?
  end

  test "lock! sets locked_at timestamp" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")

    questionnaire.lock!
    assert_not_nil questionnaire.locked_at
    assert questionnaire.locked?
  end

  test "should have many categories" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")
    cat1 = questionnaire.categories.create!(name: "Personal", position: 1)
    cat2 = questionnaire.categories.create!(name: "Work", position: 2)

    assert_equal 2, questionnaire.categories.count
    assert_includes questionnaire.categories, cat1
    assert_includes questionnaire.categories, cat2
  end

  test "should destroy dependent categories when destroyed" do
    org = Organization.create!(name: "Acme")
    questionnaire = org.questionnaires.create!(title: "Survey")
    questionnaire.categories.create!(name: "Personal", position: 1)

    assert_difference "Category.count", -1 do
      questionnaire.destroy
    end
  end
end
