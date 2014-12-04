module HierMenu
  class HierMenu
    def initialize(nav_item, collection, diplay_property, url_proc, max_width = 5)
      # if (collection.count <= max_width)
        collection.each do |item|
          nav_item.item url_proc.call(item), 
                        item.read_attribute(diplay_property),
                        url_proc.call(item)
        end
      # end
      
      
      # puts "Hello world", collection.first, collection.first.read_attribute(diplay_property), url_proc.call(collection.first)
    end
  end
end