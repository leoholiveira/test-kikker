class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, :body, :ip, presence: true

  def self.top_by_average_rating(n)
    n = n.to_i
    return none if n <= 0

    left_joins(:ratings)
      .select("posts.*, COALESCE(AVG(ratings.value)::float, 0) AS avg_rating")
      .group("posts.id")
      .order("avg_rating DESC, posts.id DESC")
      .limit(n)
  end

  def average_rating_value
    value = ratings.average(:value)
    value.nil? ? nil : value.to_f.round(2)
  end
end
