class AddEmailToBcmsBlog < ActiveRecord::Migration

  def self.up
    add_content_column :bcms_blog_blogs, :email, :string
  end

  def self.down
    remove_column :bcms_blog_blogs, :email
    remove_column :bcms_blog_blog_versions, :email
  end

end
