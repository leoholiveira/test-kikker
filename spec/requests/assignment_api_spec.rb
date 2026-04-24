require "rails_helper"

RSpec.describe "Assignment API", type: :request do
  describe "POST /posts" do
    it "creates the user and post and returns post and user JSON" do
      expect {
        post "/posts", params: {
          title: "T1", body: "B1", login: "alice", ip: "198.51.100.1"
        }, as: :json
      }.to change(User, :count).by(1).and change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["post"]["title"]).to eq("T1")
      expect(json["post"]["body"]).to eq("B1")
      expect(json["post"]["ip"]).to eq("198.51.100.1")
      expect(json["user"]["login"]).to eq("alice")
    end

    it "reuses an existing user for the same login" do
      create(:user, login: "bob")
      expect {
        post "/posts", params: {
          title: "T2", body: "B2", login: "bob", ip: "198.51.100.2"
        }, as: :json
      }.to change(Post, :count).by(1).and change(User, :count).by(0)
    end

    it "returns validation errors when the post is invalid" do
      post "/posts", params: { title: "", body: "B", login: "c", ip: "1.1.1.1" }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "POST /ratings" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    it "returns the post average and allows only one rating per user per post" do
      post "/ratings", params: { rating: { post_id: post_record.id, user_id: user.id, value: 4 } },
                       as: :json
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["average_rating"]).to eq(4.0)

      post "/ratings", params: { rating: { post_id: post_record.id, user_id: user.id, value: 5 } },
                       as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /posts/top" do
    it "returns the top N posts by average rating" do
      p_low = create(:post)
      p_high = create(:post)
      create(:rating, post: p_low, value: 1)
      create(:rating, post: p_high, value: 5)
      create(:rating, post: p_high, user: create(:user), value: 5)

      get "/posts/top?n=1", as: :json
      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data.length).to eq(1)
      expect(data.first.keys).to match_array(%w[id title body])
      expect(data.first["id"]).to eq(p_high.id)
    end
  end

  describe "GET /posts/ips_by_authors" do
    it "returns each IP with distinct author logins" do
      u1 = create(:user, login: "a")
      u2 = create(:user, login: "b")
      create(:post, user: u1, ip: "10.0.0.1")
      create(:post, user: u2, ip: "10.0.0.1")
      create(:post, user: u2, ip: "10.0.0.2")

      get "/posts/ips_by_authors", as: :json
      expect(response).to have_http_status(:ok)
      by_ip = response.parsed_body.index_by { |h| h["ip"] }
      expect(by_ip["10.0.0.1"]["logins"].sort).to eq(%w[a b])
      expect(by_ip["10.0.0.2"]["logins"]).to eq(%w[b])
    end
  end
end
