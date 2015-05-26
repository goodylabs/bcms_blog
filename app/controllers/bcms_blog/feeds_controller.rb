module BcmsBlog
  class FeedsController < ApplicationController
  
    def index
      id = params[:blog_id] || params[:id]
      unless id.blank?
        @blog = Blog.find_by(id: id)
        @blog_posts = @blog.posts.published.all(:limit => 10, :order => "published_at DESC") if @blog
      end
    end
  
  end
end