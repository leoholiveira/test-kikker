require "rails_helper"

RSpec.describe "/users (scaffold)" do
  it "loads the model" do
    expect(User).to be < ApplicationRecord
  end
end
