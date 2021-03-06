# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3.1
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      "managers" => ["managers"],
      "human-resources" => ["human-resources"],
      "accounting-finance" => ["accounting-finance"],
      "pr-communications" => ["pr-communications"],
      "youth-programs" => ["youth-programs"],
      "member-service" => ["member-service"],
      "broadband" => ["broadband"],
      "eando-circle" => ["eando-circle"],
      "admins-circle" => ["admins-circle"],
      "it-circle" => ["it-circle"],
      "govaffairs-circle" => ["govaffairs-circle"]
      # "everyone" makes every user watch the listed categories
      # "everyone" => [ "announcements" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == "everyone"
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 10.minutes

      def execute(args)
        puts "Updating watch status for each category"
        WatchCategory.watch_category!
      end
    end
  end
end
