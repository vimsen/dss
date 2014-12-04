module HierMenu
  @item_id = 0
  def HierMenu::make_menu(nav_item, collection, diplay_property, url_proc,     
                          max_width = 4)
    if collection.count < max_width
      collection.each do |item|
        @item_id += 1
        nav_item.item "hier_menu_#{@item_id}", 
                      item.read_attribute(diplay_property),
                      url_proc.call(item)
      end
    else
      collection.each_slice(collection.count / (max_width - 1)) do |slice|
        @item_id += 1
        if slice.count == 1
          nav_item.item "hier_menu_#{@item_id}", 
                        slice.first.read_attribute(diplay_property),
                        url_proc.call(slice.first)
        else
          nav_item.item "hier_menu_#{@item_id}", 
                "#{slice.first.read_attribute(diplay_property)}"\
                "..#{slice.last.read_attribute(diplay_property)}",
                url_proc.call(slice.first), :split => false do |sub_nav|
            make_menu sub_nav, slice, diplay_property, url_proc
            sub_nav.dom_class = 'nav nav-third-level collapse'
          end
        end
      end
    end
  end
end