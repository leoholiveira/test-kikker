require "rails_helper"

RSpec.describe Post, type: :model do
  subject { build(:post) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_presence_of(:ip) }
end
