require "rails_helper"

RSpec.describe Rating, type: :model do
  subject { build(:rating) }

  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to validate_inclusion_of(:value).in_range(1..5) }
  it do
    is_expected.to validate_uniqueness_of(:user_id)
      .scoped_to(:post_id)
      .with_message("Só é possível avaliar uma publicação uma vez.")
  end
end
