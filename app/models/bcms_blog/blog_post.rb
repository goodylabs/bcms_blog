module BcmsBlog
  class BlogPost < ActiveRecord::Base
    acts_as_content_block :taggable => true

    has_attachment :file, styles: { medium: '710x355#', small: '353x475#' }

    has_attachment :video
    has_many :references, as: :referencable

    before_save :set_published_at

    belongs_to :blog


    has_and_belongs_to_many :categories, class_name: "Cms::Category", join_table: "bcms_blog_blog_posts_categories"
    has_and_belongs_to_many :subcategories, class_name: "Cms::Category", join_table: "bcms_blog_blog_posts_subcategories"

    # belongs_to_category
    # belongs_to :subcategory, :class_name => 'Cms::Category'

    scope :published_and_visible, lambda{
      published.where('published_at <= ? ', DateTime.now)
    }

    scope :in_category, lambda{|cat|
      joins(:categories).where('cms_categories.id' => cat.id)
    }
    scope :in_subcategory, lambda{|cat|
      joins(:subcategories).where('subcategories.id' => cat.id)
    }

    scope :in_categories, lambda{|cats|
      joins(:categories).where('cms_categories.id IN (?)', cats.map(&:id))
    }
    scope :in_subcategories, lambda{|cats|
      joins(:subcategories).where('cms_categories.id IN (?)', cats.map(&:id))
    }

    scope :in_category_and_subcategory, lambda {|category, subcategory|
      cats = [category, subcategory].flatten.reject(&:nil?)
      a = joins(:categories)
      unless subcategory.nil?
        a = a.joins(:subcategories)
      end
      a.where('cms_categories.id IN (?)', cats.map(&:id))
    }

    scope :in_categories_and_subcategories, lambda {|post|
      cats = [post.categories, post.subcategories].flatten
      a = joins(:categories)
      if post.subcategories.any?
        a = a.joins(:subcategories)
      end
      a.where('cms_categories.id IN (?)', cats.map(&:id))
    }

    scope :in_categories_by_name, lambda{|categories_names|
     joins(:categories).where('lower(cms_categories.name) IN (?)', categories_names)
    }

    scope :in_categories_and_subcategories_by_name, lambda{|categories_names|
      joins(:categories).joins(:subcategories).where('lower(cms_categories.name) IN (?)', categories_names)
    }

    belongs_to :author, :class_name => "Cms::User"
    has_many :comments, :class_name => "BlogComment", :foreign_key => "post_id"

    before_validation :set_slug
    validates_presence_of :name, :slug, :blog_id, :author_id, :published_at
    validate :must_have_at_least_one_category

    def must_have_at_least_one_category
      if categories.empty? or categories.all? {|child| child.marked_for_destruction? }
        errors.add(:base, 'Must have at least one category')
      end
    end

    scope :homepage_featured_first, lambda {
      reorder(on_homepage: :desc, featured: :desc, published_at: :desc)
    }

    scope :featured_first, lambda{
      reorder(featured: :desc, published_at: :desc)
    }

    scope :featured, lambda {
      where(featured: true)
    }

    scope :not_featured, lambda {
      where(featured: false)
    }



    scope :published_between, lambda { |start, finish|
      { :conditions => [
           "#{table_name}.published_at >= ? AND #{table_name}.published_at < ?",
           start, finish ] }
    }

    scope :not_tagged_with, lambda { |tag| {
      :conditions => [
        "#{table_name}.id not in (
          SELECT taggings.taggable_id FROM taggings
          JOIN tags ON tags.id = taggings.tag_id
          WHERE taggings.taggable_type = 'BlogPost'
          AND (tags.name = ?)
        )",
        tag
      ]
    } }

    scope :authored_by, lambda{ |user, published=true|
      where(author: user, published: published)
    }

    scope :authored_by_name, lambda{ |user_name, published=true|
      where("author_name LIKE ? AND published = ? ", "%#{user_name}%", published)
      # where(author_name: user_name, published: published)
    }

    INCORRECT_PARAMETERS = "Incorrect parameters. This is probably because you are trying to view the " +
                           "portlet through the CMS interface, and so we have no way of knowing what " +
                           "post(s) to show"

    delegate :editable_by?, :to => :blog



    def self.columns_for_index
      [
       {:label => "Published At", :method => :published_at, :order => "#{BlogPost.table_name}.published_at"},
       {:label => "Featured", :method => :featured, :order => "#{BlogPost.table_name}.featured"},
       {:label => "On Homepage", :method => :on_homepage, :order => "#{BlogPost.table_name}.on_homepage"},
       {:label => "Blog", :method => :blog_name, :order => "#{BlogPost.table_name}.blog"},
       {:label => "Author", :method => :published_author_name, :order => "#{BlogPost.table_name}.author"},
       {:label => "Name", :method => :name, :order => "#{BlogPost.table_name}.name"},
       {:label => "Categories", :method => :categories_names},
       {:label => "Subcategory", :method => :subcategories_names}
      ]
    end

    def extract_content_paragraph
      summary = ""
      if email_summary.blank?
        text = Nokogiri::HTML.parse(self.body).css('p').first.text
        words = text.split(" ")
        summary = words.length > 175 ? "#{words.first(175).join(" ")}..." : text
      else
        summary = self.email_summary
      end
      summary
    end

    def categories_and_subcategories_ids
      [self.categories, self.subcategories].flatten.map(&:id)
    end

    def related_posts_by_category_and_subcategory
      self.blog.posts.in_categories_and_subcategories(self).where("NOT bcms_blog_blog_posts.id=?",self.id ).uniq
    end


    def blog_name
      blog.name unless blog.nil?
    end

    def author_full_name
      author.full_name unless author.nil?
    end

    def published_author_name
      return "" if self.hide_author
      return self.author_name unless self.author_name.blank?
      return self.author.full_name unless self.author.nil?
      ""
    end

    def categories_names
      categories.map(&:name).join(", ") unless categories.empty?
    end

    def subcategories_names
      subcategories.map(&:name).join(", ") unless subcategories.empty?
    end

    def set_published_at
      if !published_at && publish_on_save
        self.published_at = Time.now
      end
    end

    # This is necessary because, oddly, the publish! method in the Publishing behaviour sends an update
    # query directly to the database, bypassing callbacks, so published_at does not get set by our
    # set_published_at callback.
    def after_publish_with_set_published_at
      if published_at.nil?
        self.published_at = Time.now
        self.save!
      end
      after_publish_without_set_published_at if respond_to? :after_publish_without_set_published_at
    end
    if instance_methods.map(&:to_s).include? 'after_publish'
      alias_method_chain :after_publish, :set_published_at
    else
      alias_method       :after_publish, :after_publish_with_set_published_at
    end

    def self.default_order
      "created_at desc"
    end

    # def self.columns_for_index
    #   [ {:label => "Name", :method => :name, :order => "name" },
    #     {:label => "Published At", :method => :published_label, :order => "published_at" } ]
    # end

    def published_label
      published_at ? published_at.to_s(:date) : nil
    end

    def set_slug
      self.slug = generate_slug(name.to_slug)
      # self.slug = name.to_slug
    end

    def path
      send("#{blog.name_for_path}_post_path", route_params)
    end
    def route_name
      "#{blog.name_for_path}_post"
    end
    def route_params
      {:year => year, :month => month, :day => day, :slug => slug}
    end

    def year
      published_at.strftime("%Y") unless published_at.blank?
    end

    def month
      published_at.strftime("%m") unless published_at.blank?
    end

    def day
      published_at.strftime("%d") unless published_at.blank?
    end

    # Return true if this model has an attachment
    def attachment
      !file.blank?
    end


    def teaser_video_url
      res = self.video_url
      unless self.video.nil?
        unless self.video.path.nil?
          res = self.video.url
        end
      end
      res
    end

    def teaser_image_url(style=nil)
      res = self.image_url
      unless self.file.nil?
        unless self.file.path.nil?
          res = style.blank? ? self.file.url : self.file.url(style)
        end
      end
      res
    end

    private

    def generate_slug(slug, suffix = '')
      unless BcmsBlog::BlogPost.where('slug LIKE ? AND id NOT IN (?)' , [slug, suffix].join, id.to_i).empty?
        generate_slug(slug, suffix.to_i - 1)
      else
        [slug, suffix].join
      end
    end


  end
end
