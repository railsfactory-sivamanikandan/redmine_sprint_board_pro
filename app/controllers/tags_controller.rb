class TagsController < ApplicationController
  def autocomplete
    q = params[:q].to_s
    tags = ActsAsTaggableOn::Tag.where("name LIKE ?", "%#{q}%").limit(10)
    render json: tags
  end
end