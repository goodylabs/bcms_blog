class AddOnHomepageToBcmsBlogBlogPost < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :on_homepage, :boolean, defaut: false
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :on_homepage
    remove_column :bcms_blog_blog_post_versions, :on_homepage
  end
end
