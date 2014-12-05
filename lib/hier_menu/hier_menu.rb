module HierMenu
  class HierMenu
    def initialize menu_id, 
                   url_proc,
                   diplay_property = nil, 
                   max_width = 4
      @item_id = 0
      @menu_id = menu_id
      diplay_property ||= "name"
      @diplay_property = diplay_property
      @url_proc = url_proc
      @max_width = max_width
    end

    def fill_node(nav_item, collection, level = 3)
      if collection.count < @max_width
        collection.each do |item|
          @item_id += 1
          nav_item.item "#{@menu_id}_#{@item_id}", 
                        item.read_attribute(@diplay_property),
                        @url_proc.call(item)
        end
      else
        sz = slice_size collection.count
        puts "slice size: #{sz}, #{level}, #{collection.count}"
        collection.each_slice(sz) do |slice|
          @item_id += 1
          if slice.count == 1
            nav_item.item "#{@menu_id}_#{@item_id}", 
                          slice.first.read_attribute(@diplay_property),
                          @url_proc.call(slice.first)
          else
            nav_item.item "#{@menu_id}_#{@item_id}", 
                  "#{slice.first.read_attribute(@diplay_property)}"\
                  "..#{slice.last.read_attribute(@diplay_property)}",
                  @url_proc.call(slice.first), :split => false do |sub_nav|
              fill_node sub_nav, slice, level + 1
              sub_nav.dom_class = "nav nav-#{to_word(level)}-level collapse"
            end
          end
        end
      end
    end
    
    private
    
    def to_word(number)
      ["zero", "first", "second", "third", "fourth", "fifth", "sixth"][number]
    end   
    
    def slice_size(num_items)
      result = 1
      loop do
        if (result * @max_width >= num_items)
          return result
        end
        result *= @max_width
      end
    end 
    
  end

end