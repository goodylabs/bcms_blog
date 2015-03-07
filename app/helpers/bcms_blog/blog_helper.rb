module BcmsBlog
  module BlogHelper
    # We can't call it 'blog_path' because that would conflict with the actual named route method if there's a blog named "Blog".

    def _blog_url(blog, route_name, route_params)
      send("#{blog.name_for_path}_#{route_name}_url", route_params)
    end

    def _blog_path(blog, route_name, route_params)
      send("#{blog.name_for_path}_#{route_name}_path", route_params)
    end

    def _blog_post_url(blog_post)
      send("#{blog_post.route_name}_url", blog_post.route_params)
    end

    def _blog_post_path(blog_post)
      send("#{blog_post.route_name}_path", blog_post.route_params)
    end

    def feeds_link_tag_for(name)
      blog = Blog.find_by_name(name)
      auto_discovery_link_tag(:rss, main_app.blog_feeds_url(:blog_id => blog), :title => "#{blog.name}")
    end

    def new_comment_params(portlet)
      {:url=> Cms::Engine.routes.url_helpers.portlet_handler_path(:id=>portlet.id, :handler=>'create_comment'),
      :method=>'post'}
    end

    def categories_by_type_id(category_type_id, order="name")
      return [Cms::Category.new(:name => "-- You must choose proper blog to see categories --")] if category_type_id.blank?
      cat_type = Cms::CategoryType.find_by(id: category_type_id)
      categories = cat_type ? cat_type.category_list(order) : [Category.new(:name => "-- You must choose proper blog to see categories")]
      categories.empty? ? [Cms::Category.new(:name => "-- You must first create a Category with a Category Type of '#{category_type_name}'.")] : categories
    end

  end
end
