class AddCategoryTypeToBlog < ActiveRecord::Migration
  def change
    add_reference :bcms_blog_blogs, :category_type, index: true
    add_reference :bcms_blog_blog_versions, :category_type, index: true
  end
end
