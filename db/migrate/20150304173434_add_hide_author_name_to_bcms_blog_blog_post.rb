class AddHideAuthorNameToBcmsBlogBlogPost < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :hide_author, :boolean, :default => false
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :hide_author
    remove_column :bcms_blog_blog_post_versions, :hide_author
  end
end
