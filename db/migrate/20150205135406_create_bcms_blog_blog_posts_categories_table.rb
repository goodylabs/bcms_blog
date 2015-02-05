class CreateBcmsBlogBlogPostsCategoriesTable < ActiveRecord::Migration
  def change
    create_table :bcms_blog_blog_posts_categories_tables do |t|
      t.belongs_to :blog_post
      t.belongs_to :category
    end
  end
end
