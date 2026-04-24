class RatingsController < ApplicationController
  before_action :set_rating, only: %i[ show update destroy ]

  # GET /ratings
  def index
    @ratings = Rating.all

    render json: @ratings
  end

  # GET /ratings/1
  def show
    render json: @rating
  end

  # POST /ratings
  def create
    @rating = Rating.new(rating_for_create)
    begin
      if @rating.save
        return render json: { average_rating: @rating.post.reload.average_rating_value },
                      status: :created
      end
    rescue ActiveRecord::RecordNotUnique
      return render json: { errors: { user_id: [ "já avaliou esta publicação" ] } },
                    status: :unprocessable_content
    end

    render json: { errors: @rating.errors.to_hash(true) },
           status: :unprocessable_content
  end

  # PATCH/PUT /ratings/1
  def update
    if @rating.update(rating_params)
      render json: @rating
    else
      render json: @rating.errors, status: :unprocessable_content
    end
  end

  # DELETE /ratings/1
  def destroy
    @rating.destroy!
  end

  private
    def set_rating
      @rating = Rating.find(params.expect(:id))
    end

    def rating_params
      params.expect(rating: [ :post_id, :user_id, :value ])
    end

    def rating_for_create
      if params.key?(:rating)
        params.require(:rating).permit(:post_id, :user_id, :value)
      else
        params.permit(:post_id, :user_id, :value)
      end
    end
end
