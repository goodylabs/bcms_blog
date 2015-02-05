class CreateBcmsBlogBlogPostsSubcategoriesTable < ActiveRecord::Migration
  def change
    create_table :bcms_blog_blog_posts_subcategories do |t|
      t.belongs_to :blog_post
      t.belongs_to :category
    end
  end
end
