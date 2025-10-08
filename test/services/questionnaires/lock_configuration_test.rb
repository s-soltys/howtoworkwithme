require "test_helper"

class Questionnaires::LockConfigurationTest < ActiveSupport::TestCase
  test "locks questionnaire when it has no locked_at timestamp" do
    questionnaire = questionnaires(:unlocked_questionnaire)
    assert_nil questionnaire.locked_at

    result = Questionnaires::LockConfiguration.call(questionnaire)

    assert result.success?
    questionnaire.reload
    assert_not_nil questionnaire.locked_at
  end

  test "does not lock questionnaire if already locked" do
    questionnaire = questionnaires(:locked_questionnaire)
    original_locked_at = questionnaire.locked_at
    assert_not_nil original_locked_at

    result = Questionnaires::LockConfiguration.call(questionnaire)

    assert result.success?
    questionnaire.reload
    assert_equal original_locked_at.to_i, questionnaire.locked_at.to_i
  end

  test "returns failure if questionnaire is invalid" do
    questionnaire = Questionnaire.new # Invalid questionnaire

    result = Questionnaires::LockConfiguration.call(questionnaire)

    assert_not result.success?
    assert_includes result.errors, "Questionnaire must be persisted"
  end

  test "locks questionnaire when first response is submitted" do
    questionnaire = questionnaires(:unlocked_questionnaire)
    assert_nil questionnaire.locked_at

    # Simulate first submission
    result = Questionnaires::LockConfiguration.call(questionnaire)

    assert result.success?
    questionnaire.reload
    assert_not_nil questionnaire.locked_at
    assert questionnaire.locked?
  end
end
