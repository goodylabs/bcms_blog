class AddModerateCommentsToBlog < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blogs, :moderate_comments, :boolean, :default => true
  end

  def self.down
    remove_column :bcms_blog_blogs, :moderate_comments
    remove_column :bcms_blog_blog_versions, :moderate_comments
  end
end
