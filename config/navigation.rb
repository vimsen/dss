require 'hier_menu/hier_menu'

# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  
#  navigation.renderer = SimpleNavigationRenderers::Bootstrap2

# Specify a custom renderer if needed.
# The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
# The renderer can also be specified as option in the render_navigation call.
# navigation.renderer = Your::Custom::Renderer

# Specify the class that will be applied to active navigation items.
# Defaults to 'selected' navigation.selected_class = 'your_selected_class'

# Specify the class that will be applied to the current leaf of
# active navigation items. Defaults to 'simple-navigation-active-leaf'
# navigation.active_leaf_class = 'your_active_leaf_class'

# Item keys are normally added to list items as id.
# This setting turns that off
# navigation.autogenerate_item_ids = false

# You can override the default logic that is used to autogenerate the item ids.
# To do this, define a Proc which takes the key of the current item as argument.
# The example below would add a prefix to each key.
# navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

# If you need to add custom html around item names, you can define a proc that
# will be called with the name you pass in to the navigation.
# The example below shows how to wrap items spans.
# navigation.name_generator = Proc.new {|name, item| "<span>#{name}</span>"}

# The auto highlight feature is turned on by default.
# This turns it off globally (for the whole plugin)
# navigation.auto_highlight = false

# If this option is set to true, all item names will be considered as safe (passed through html_safe). Defaults to false.
# navigation.consider_item_names_as_safe = false

# Define the primary navigation
  navigation.items do |primary|

    primary.dom_id = 'side-menu'
    primary.dom_class = 'nav nav-pills nav-stacked'

    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>if: -> { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>unless: -> { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>.
    #

    primary.item :menu_home, 'Home', '/', :icon => ['fa fa-home fa-fw'] # class: 'fa fa-home fa-fw'
    primary.item :menu_prosumers, 'Prosumers', prosumers_path, :icon => ['fa fa-plug fa-fw'], :split => false do |sub_nav|
      sub_nav.item :menu_prosumers_sub, "Prosumer list", prosumers_path
      sub_nav.item :menu_prosumer_new, "New Prosumer", new_prosumer_path
      HierMenu::HierMenu.new("prosumers_hier", 
                             Proc.new { |p| prosumer_url(p) }
                            ).fill_node sub_nav, Prosumer.all.order(name: :asc) 
      sub_nav.dom_class = 'nav nav-second-level collapse'
    end
    primary.item :menu_clusters, 'Clusters', clusters_path, :icon => ['fa fa-sitemap fa-fw'], :split => false do |sub_nav|
    # primary.item :menu_clusters, 'Clusters' do |sub_nav|
      sub_nav.item :menu_clusters_sub, "Cluster list", clusters_path
     #  sub_nav.item :menu_auto_cluster, "Automatic clustering", "/clusterings/select"
      HierMenu::HierMenu.new("clusters_hier", Proc.new { |p| cluster_url(p) }, nil, 4
                            ).fill_node sub_nav, Cluster.all.order(name: :asc) 
      sub_nav.dom_class = 'nav nav-second-level collapse'
    end

    primary.item :menu_clusterings, 'Clusterings', '#' do |sub_nav|
      sub_nav.item :menu_clusterings_sub, "Clusterings List", clusterings_path
      sub_nav.item :menu_clustering_new, "New Clustering", new_clustering_path
      sub_nav.item :menu_clustering_new_from_existing, "New Clustering from existing allocation", new_from_existing_clustering_path
      HierMenu::HierMenu.new("clusterings_hier",
                             Proc.new { |p| clustering_url(p) },
                             nil,
                             4).fill_node sub_nav, Clustering.all.order(name: :asc)
      sub_nav.dom_class = 'nav nav-second-level collapse'
    end

    primary.item :menu_demand_responses, 'Demand Responses', demand_responses_path
    primary.item :menu_bids, 'Bids', bids_path
    primary.item :menu_sla, 'Monitor SLA progress', sla_monitor_path

   # primary.item :menu_meters, 'Meters', '#' do |sub_nav|
   #   HierMenu::HierMenu.new('meters_hier', Proc.new { |p| meter_url(p) }, :mac, 4).fill_node sub_nav, Meter.all.order(id: :asc)
   #   sub_nav.dom_class = 'nav nav-second-level collapse'
   # end
    primary.item :menu_algorithms, 'Algorithms', "#" do |sub_nav|
      sub_nav.item :menu_clustering, 'Clustering', "/clusterings/select"
      sub_nav.item :menu_dunamic_adaptation, 'Dynamic Adaptation', "/clusterings/new_from_existing"
      sub_nav.item :menu_target_clustering, "Target Clustering", "/target_clustering"
      sub_nav.item :menu_RES_scheduling, 'RES scheduling', "#"
      sub_nav.item :menu_VMG_modeling, 'VMG production - consumption modeling', "#"
      sub_nav.item :menu_VMG_profiling, 'VMG profile maximization algorithms', "#"
      sub_nav.item :menu_comm_algos, 'Communication algorithms', "#"
      sub_nav.item :menu_virt_netw_micro, 'Virtual netwrok microgrid', "#"
      sub_nav.dom_class = 'nav nav-second-level collapse'
    end
    primary.item :menu_data_points, 'Data points', data_points_path, :icon => ['fa fa-bar-chart-o fa-fw']
#     primary.item :menu_day_aheads, 'Day-ahead forecasts', day_aheads_path, :icon => ['fa fa-bar-chart-o fa-fw']
    primary.item :menu_market_prices, 'Market Prices', market_prices_path, :icon => ['fa fa-bar-chart-o fa-fw']
    primary.item :menu_configurations, 'Configurations', '/configurations', :icon => ['fa fa-tasks fa-fw']
    primary.item :menu_cloud_platform, 'Cloud Platform', "#" do |sub_nav| 
      sub_nav.item :menu_instances, 'Instances', '/cloud_platform', :icon => ['fa fa-cog fa-fw']
      sub_nav.item :menu_cloud_resources, 'Resources', '/cloud_platform/resources', :icon => ['fa fa-tachometer fa-fw']
      sub_nav.item :menu_engines, 'Machines', '/cloud_platform/machines', :icon => ['fa fa-server fa-fw']
      sub_nav.item :menu_tasks, 'Tasks', '/cloud_platform/tasks', :icon => ['fa fa-list fa-fw']
      sub_nav.dom_class = 'nav nav-second-level collapse'

    end
    #primary.item :menu_cloud_platform, 'Cloud Platform', '/cloud_platform', :icon => ['fa fa-cog fa-fw']
    primary.item :menu_users, 'Users', users_path, :icon => ['fa fa-user fa-fw']

  #    primary.item :key_1, 'name', url, options

  # Add an item which has a sub navigation (same params, but with block)
  #    primary.item :key_2, 'name', url, options do |sub_nav|
  # Add an item to the sub navigation (same params again)
  #      sub_nav.item :key_2_1, 'name', url, options
  #    end

  # You can also specify a condition-proc that needs to be fullfilled to display an item.
  # Conditions are part of the options. They are evaluated in the context of the views,
  # thus you can use all the methods and vars you have available in the views.
  #    primary.item :key_3, 'Admin', url, class: 'special', if: -> { current_user.admin? }
  #    primary.item :key_4, 'Account', url, unless: -> { logged_in? }

  # you can also specify html attributes to attach to this particular level
  # works for all levels of the menu
  # primary.dom_attributes = {id: 'menu-id', class: 'menu-class'}

  # You can turn off auto highlighting for a specific level
  primary.auto_highlight = true
  end
end
