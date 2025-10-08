# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create sample organization
org = Organization.find_or_create_by!(name: "Demo Company") do |o|
  o.unique_token = SecureRandom.urlsafe_base64(12)
end
puts "✅ Created organization: #{org.name}"

# Create sample questionnaire
questionnaire = org.questionnaires.find_or_create_by!(title: "Employee Onboarding Questionnaire") do |q|
  q.unique_token = SecureRandom.urlsafe_base64(12)
  q.locked_at = nil
end
puts "✅ Created questionnaire: #{questionnaire.title}"

# Create categories for different question types
categories_data = [
  { name: "Personal Preferences" },
  { name: "Work Style Assessment" },
  { name: "Team Dynamics" }
]

categories = categories_data.map.with_index do |cat_data, index|
  questionnaire.categories.find_or_create_by!(name: cat_data[:name]) do |c|
    c.position = index + 1
  end
end
puts "✅ Created #{categories.count} categories"

# Destroy existing questions to ensure idempotency
categories.each { |c| c.questions.destroy_all }

# Category 1: Personal Preferences
category = categories[0]
position = 1

# 1. Slider Question
category.questions.create!(
  text: "How would you describe your work style on the introvert-extrovert spectrum?",
  question_type: "slider",
  position: position,
  required: true,
  settings: {
    min_value: 1,
    max_value: 10,
    step: 1,
    labels: {
      "1" => "Very Introverted",
      "5" => "Balanced",
      "10" => "Very Extroverted"
    },
    default_value: 5
  }
)
position += 1
puts "  ✅ Created Slider question"

# 2. Swipe Yes/No Question
category.questions.create!(
  text: "Do you prefer working remotely over coming to the office?",
  question_type: "swipe_yes_no",
  position: position,
  required: true,
  settings: {
    swipe_threshold: 0.3,
    positive_label: "Yes, remote work!",
    negative_label: "No, office is better",
    animation_duration: 300
  }
)
position += 1
puts "  ✅ Created Swipe Yes/No question"

# Category 2: Work Style Assessment
category = categories[1]
position = 1

# 3. Card Sort Question
category.questions.create!(
  text: "Rank these work values from most to least important to you:",
  question_type: "card_sort",
  position: position,
  required: true,
  settings: {
    cards: [
      { id: "work-life-balance", text: "Work-Life Balance", description: "Having time for personal life and family" },
      { id: "career-growth", text: "Career Growth", description: "Opportunities for advancement and learning" },
      { id: "compensation", text: "Compensation", description: "Competitive salary and benefits" },
      { id: "team-culture", text: "Team Culture", description: "Working with supportive and collaborative teammates" },
      { id: "autonomy", text: "Autonomy", description: "Freedom to make decisions and work independently" },
      { id: "impact", text: "Impact", description: "Making a meaningful difference through your work" }
    ],
    allow_partial_ranking: false
  }
)
position += 1
puts "  ✅ Created Card Sort question"

# 4. Energy Map Question
category.questions.create!(
  text: "Map your typical energy levels throughout a work week:",
  question_type: "energy_map",
  position: position,
  required: true,
  settings: {
    time_periods: [
      "Monday Morning",
      "Monday Afternoon",
      "Tuesday Morning",
      "Tuesday Afternoon",
      "Wednesday Morning",
      "Wednesday Afternoon",
      "Thursday Morning",
      "Thursday Afternoon",
      "Friday Morning",
      "Friday Afternoon"
    ],
    scale_min: 0,
    scale_max: 10,
    scale_labels: {
      "0" => "Exhausted",
      "5" => "Moderate",
      "10" => "Highly Energized"
    },
    y_axis_label: "Energy Level",
    allow_partial: true
  }
)
position += 1
puts "  ✅ Created Energy Map question"

# Category 3: Team Dynamics
category = categories[2]
position = 1

# 5. Emoji Reaction Question
category.questions.create!(
  text: "How do you feel about attending meetings?",
  question_type: "emoji_reaction",
  position: position,
  required: true,
  settings: {
    emoji_options: [
      { emoji: "😍", label: "Love them!", value: 5 },
      { emoji: "😊", label: "They're helpful", value: 4 },
      { emoji: "😐", label: "Neutral", value: 3 },
      { emoji: "😕", label: "Could do without", value: 2 },
      { emoji: "😤", label: "Strongly dislike", value: 1 }
    ]
  }
)
position += 1
puts "  ✅ Created Emoji Reaction question"

# 6. Character Sheet Question
category.questions.create!(
  text: "Allocate 20 points across these work style attributes to describe yourself:",
  question_type: "character_sheet",
  position: position,
  required: true,
  settings: {
    total_points: 20,
    stats: [
      { id: "leadership", label: "Leadership", description: "Guiding and inspiring others", min: 0, max: 10 },
      { id: "technical", label: "Technical Skills", description: "Coding and system design expertise", min: 0, max: 10 },
      { id: "creative", label: "Creativity", description: "Innovative and out-of-the-box thinking", min: 0, max: 10 },
      { id: "communication", label: "Communication", description: "Written and verbal expression", min: 0, max: 10 },
      { id: "analytical", label: "Analytical Thinking", description: "Data-driven decision making", min: 0, max: 10 }
    ],
    require_full_allocation: true
  }
)
position += 1
puts "  ✅ Created Character Sheet question"

# Create a sample employee response
employee = org.employees.find_or_create_by!(name: "Sample Employee", email: "sample@example.com")

response = employee.responses.find_or_create_by!(questionnaire: questionnaire) do |r|
  r.unique_token = SecureRandom.urlsafe_base64(12)
  r.submitted_at = nil
end
puts "✅ Created sample employee and response"

puts "\n🎉 Seeding complete!"
puts "\n📋 Access URLs:"
puts "  Admin (edit questionnaire): /questionnaires/#{questionnaire.unique_token}/edit"
puts "  Employee (fill questionnaire): /responses/#{response.unique_token}/edit"
