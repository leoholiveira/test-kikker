class Rating < ApplicationRecord
  belongs_to :post
  belongs_to :user

  validates :value, inclusion: { in: 1..5 }
end
