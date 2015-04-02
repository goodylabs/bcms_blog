class AddDarkFilterEnabledToBcmsBlogPosts < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :dark_filter_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :dark_filter_enabled
    remove_column :bcms_blog_blog_post_versions, :dark_filter_enabled
  end
end