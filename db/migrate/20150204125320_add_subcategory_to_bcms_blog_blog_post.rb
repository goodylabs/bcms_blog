class AddSubcategoryToBcmsBlogBlogPost < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :subcategory_id, :integer
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :subcategory_id
    remove_column :bcms_blog_blog_post_versions, :subcategory_id
  end
end
