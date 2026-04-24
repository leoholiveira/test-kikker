class PostsController < ApplicationController
  wrap_parameters false

  before_action :set_post, only: %i[ show update destroy ]

  # GET /posts
  def index
    @posts = Post.all

    render json: @posts
  end

  # GET /posts/1
  def show
    render json: @post
  end

  # GET /posts/top?n=10
  def top
    n = (params[:n].presence || 10).to_i
    if n <= 0
      return render json: { errors: { n: [ "deve ser um inteiro positivo" ] } }, status: :unprocessable_content
    end
    if n > 200
      return render json: { errors: { n: [ "é maior que o permitido" ] } }, status: :unprocessable_content
    end

    @posts = Post.top_by_average_rating(n)
    render json: @posts.map { |post| post.as_json(only: %i[ id title body ]) }
  end

  # GET /posts/ips_by_authors
  def ips_by_authors
    payload = Post
      .includes(:user)
      .group_by(&:ip)
      .map do |ip, posts_by_ip|
        { ip: ip, logins: posts_by_ip.map { |p| p.user.login }.uniq.sort }
      end
      .sort_by { |h| h[:ip] }
    render json: payload
  end

  # POST /posts
  def create
    attributes = post_creation_attributes

    if attributes[:login].blank?
      return render json: { errors: { login: [ "não pode ficar em branco" ] } }, status: :unprocessable_content
    end

    @post = nil
    @user = nil

    ActiveRecord::Base.transaction do
      @user = find_or_create_user_by_login!(attributes[:login].to_s)
      @post = @user.posts.build(
        title: attributes[:title],
        body: attributes[:body],
        ip: attributes[:ip]
      )
      @post.save
    end

    if @post.persisted?
      render json: { post: @post.as_json, user: @user.as_json },
             status: :created
    else
      render json: { errors: @post.errors.to_hash(true) }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_content
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy!
  end

  private
    def find_or_create_user_by_login!(login)
      found = User.find_by(login: login)
      return found if found

      User.create!(login: login)
    rescue ActiveRecord::RecordNotUnique
      User.find_by!(login: login)
    rescue ActiveRecord::RecordInvalid => e
      if e.record.is_a?(User) && e.record.errors.added?(:login, :taken)
        User.find_by!(login: login)
      else
        raise
      end
    end

    def set_post
      @post = Post.find(params.expect(:id))
    end

    def post_params
      params.expect(post: [ :user_id, :title, :body, :ip ])
    end

    def post_creation_attributes
      top = params.permit(:title, :body, :login, :ip).to_h.symbolize_keys
      return top unless params.key?(:post) && params[:post].is_a?(ActionController::Parameters)

      nested = params.require(:post).permit(:title, :body, :ip, :login).to_h.symbolize_keys
      # Prefer top-level keys (e.g. `login` when only Post columns were wrapped)
      nested.merge(top) { |_, n, t| t.presence || n }
    end
end
