FactoryBot.define do
  factory :post do
    user
    title { Faker::Lorem.sentence(word_count: 6) }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    ip { Faker::Internet.ip_v4_address }
  end
end
