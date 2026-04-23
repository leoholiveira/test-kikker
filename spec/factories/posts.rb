FactoryBot.define do
  factory :post do
    user { nil }
    title { "MyString" }
    body { "MyText" }
    ip { "MyString" }
  end
end
