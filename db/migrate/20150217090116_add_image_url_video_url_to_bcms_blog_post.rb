class AddImageUrlVideoUrlToBcmsBlogPost < ActiveRecord::Migration
  def self.up
    add_content_column :bcms_blog_blog_posts, :video_url, :string
    add_content_column :bcms_blog_blog_posts, :image_url, :string
  end


  def self.down

    remove_column :bcms_blog_blog_posts, :video_url
    remove_column :bcms_blog_blog_post_versions, :video_url

    remove_column :bcms_blog_blog_posts, :image_url
    remove_column :bcms_blog_blog_post_versions, :image_url

  end
end
