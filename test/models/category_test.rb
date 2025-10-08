require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.build(name: "Personal", position: 1)
    assert category.valid?
  end

  test "should require name" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.build(position: 1)
    assert_not category.valid?
  end

  test "should require unique name per questionnaire" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    quest.categories.create!(name: "Personal", position: 1)
    duplicate = quest.categories.build(name: "Personal", position: 2)
    assert_not duplicate.valid?
  end

  test "should allow same name in different questionnaires" do
    org = Organization.create!(name: "Acme")
    quest1 = org.questionnaires.create!(title: "Survey 1")
    quest2 = org.questionnaires.create!(title: "Survey 2")
    quest1.categories.create!(name: "Personal", position: 1)
    category2 = quest2.categories.build(name: "Personal", position: 1)
    assert category2.valid?
  end
end
