class AddEmailSummaryToBcmsBlogBlogPosts < ActiveRecord::Migration
  def change
    add_content_column :bcms_blog_blog_posts, :email_summary, :text
  end
end
