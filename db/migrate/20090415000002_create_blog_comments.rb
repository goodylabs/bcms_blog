class CreateBlogComments < ActiveRecord::Migration
  def self.up
    create_content_table :bcms_blog_blog_comments do |t|
      t.integer :post_id
      t.string :author
      t.string :email
      t.string :url
      t.string :ip
      t.text :body
    end
  end

  def self.down
    drop_table :bcms_blog_blog_comment_versions
    drop_table :bcms_blog_blog_comments
  end
end
