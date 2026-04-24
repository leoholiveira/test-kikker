require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_presence_of(:login) }
  it { is_expected.to validate_uniqueness_of(:login) }
end
