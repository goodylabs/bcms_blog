module BcmsBlog
  class BlogPost < ActiveRecord::Base
    acts_as_content_block :taggable => true

    has_attachment :file, styles: { medium: '710x355#', small: '353x475#' }

    has_attachment :video


    before_save :set_published_at

    belongs_to :blog


    has_and_belongs_to_many :categories, class_name: "Cms::Category", join_table: "bcms_blog_blog_posts_categories"
    has_and_belongs_to_many :subcategories, class_name: "Cms::Category", join_table: "bcms_blog_blog_posts_subcategories"

    # belongs_to_category
    # belongs_to :subcategory, :class_name => 'Cms::Category'

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

    scope :in_categories_and_subcategories, lambda {|post|
      cats = [post.categories, post.subcategories].flatten
      joins(:categories).joins(:subcategories).where('cms_categories.id IN (?)', cats.map(&:id))
    }

    scope :in_categories_by_name, lambda{|categories_names|
     joins(:categories).where('cms_categories.name IN (?)', categories_names)
    }

    scope :in_categories_and_subcategories_by_name, lambda{|categories_names|
      joins(:categories).joins(:subcategories).where('cms_categories.name IN (?)', categories_names)
    }

    belongs_to :author, :class_name => "Cms::User"
    has_many :comments, :class_name => "BlogComment", :foreign_key => "post_id"

    before_validation :set_slug
    validates_presence_of :name, :slug, :blog_id, :author_id
    validate :must_have_at_least_one_category

    def must_have_at_least_one_category
      if categories.empty? or categories.all? {|child| child.marked_for_destruction? }
        errors.add(:base, 'Must have at least one category')
      end
    end

    scope :fetured_first, lambda{
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

    INCORRECT_PARAMETERS = "Incorrect parameters. This is probably because you are trying to view the " +
                           "portlet through the CMS interface, and so we have no way of knowing what " +
                           "post(s) to show"

    delegate :editable_by?, :to => :blog



    def self.columns_for_index
      [
       {:label => "Published At", :method => :published_at, :order => "#{BlogPost.table_name}.published_at"},
       {:label => "Featured", :method => :featured, :order => "#{BlogPost.table_name}.featured"},
       {:label => "Blog", :method => :blog_name, :order => "#{BlogPost.table_name}.blog"},
       {:label => "Author", :method => :author_name, :order => "#{BlogPost.table_name}.author"},
       {:label => "Name", :method => :name, :order => "#{BlogPost.table_name}.name"},
       {:label => "Categories", :method => :categories_names},
       {:label => "Subcategory", :method => :subcategories_names}
      ]
    end


    def categories_and_subcategories_ids
      [self.categories, self.subcategories].flatten.map(&:id)
    end

    def related_posts_by_category_and_subcategory
      self.blog.posts.in_categories_and_subcategories(self).where.not(:id, self.id ).uniq
    end


    def blog_name
      blog.name unless blog.nil?
    end

    def author_name
      author.full_name unless author.nil?
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
      self.slug = name.to_slug
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
      self.video.present? ? self.video.url : self.video_url
    end

    def teaser_image_url
      self.file.present? ? self.file.url : self.image_url
    end

  end
end