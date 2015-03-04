class AddAuthorNameToBcmsBlogBlogPosts < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :author_name, :string
  end

  def self.down
    remove_column :bcms_blog_blog_posts, :author_name
    remove_column :bcms_blog_blog_post_versions, :author_name
  end

end
