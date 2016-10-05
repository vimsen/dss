module HierMenu
  # This class is used for creating a hierarchical menu
  # with simple-navigation. The module will add an collection
  # of models, and will split it hierarchically so that the
  # number of children are limited.
  class HierMenu
    def initialize(menu_id, # A unique string used as the element id
                   url_proc, # a Proc that returns the url of the object
                   diplay_property = nil, # The property that wiil be used
                   #                        as the title in the menu
                   max_width = 4) # The maximum number of children of
      #                             each element
      @item_id = 0
      @menu_id = menu_id
      diplay_property ||= 'name'
      @diplay_property = diplay_property
      @url_proc = url_proc
      @max_width = max_width
    end

    def fill_node(nav_item, collection, level = 3)
      if collection.count < @max_width
        collection.each { |item| menu_add_single nav_item, item }
      else
        collection.each_slice(slice_size collection.count) do |slice|
          menu_add nav_item, slice, level
        end
      end
    end

    private

    def menu_add(nav_item, slice, level)
      if slice.count == 1
        menu_add_single nav_item, slice.first
      else
        menu_add_collection nav_item, slice, level
      end
    end

    def menu_add_single(nav_item, item)
      @item_id += 1
      nav_item.item "#{@menu_id}_#{@item_id}",
                    item.read_attribute(@diplay_property),
                    @url_proc.call(item)
    end

    def menu_add_collection(nav_item, slice, level)
      @item_id += 1
      nav_item.item "#{@menu_id}_#{@item_id}",
                    "#{slice.first.read_attribute(@diplay_property)}"\
                    "..#{slice.last.read_attribute(@diplay_property)}",
                    '#',
                    split: false do |sub_nav|
        fill_node sub_nav, slice, level + 1
        sub_nav.dom_class = "nav nav-#{to_word(level)}-level collapse"
      end
    end

    def to_word(number)
      %w(zero first second third fourth fifth sixth seventh eighth)[number]
    end

    def slice_size(num_items)
      result = 1
      loop do
        return result if result * @max_width >= num_items
        result *= @max_width
      end
    end
  end
end
