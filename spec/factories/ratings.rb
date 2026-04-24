FactoryBot.define do
  factory :rating do
    post
    user
    value { Faker::Number.between(from: 1, to: 5) }
  end
end
