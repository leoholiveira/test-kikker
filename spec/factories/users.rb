FactoryBot.define do
  factory :user do
    sequence(:login) { |n| "#{Faker::Internet.username(specifier: 8..12)}_#{n}" }
  end
end
