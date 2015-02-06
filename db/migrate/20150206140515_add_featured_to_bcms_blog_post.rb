class AddFeaturedToBcmsBlogPost < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :featured, :boolean, defaut: false
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :featured
    remove_column :bcms_blog_blog_post_versions, :featured
  end
end