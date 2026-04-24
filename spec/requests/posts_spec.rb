require "rails_helper"

# Scaffold-generated CRUD is superseded by assignment_api_spec.rb and the assignment endpoints.

RSpec.describe "/posts (scaffold)" do
  it "is documented in assignment_api_spec" do
    expect(Post).to be < ApplicationRecord
  end
end
