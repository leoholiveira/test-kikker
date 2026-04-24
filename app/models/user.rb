class User < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error
  has_many :ratings, dependent: :restrict_with_error

  validates :login, presence: true, uniqueness: true
end
