module ApplicationHelper
  
    def setActiveMenuItem(menuItem)
        if request.fullpath.include? menuItem
           'class="active"'            
        end
    end

end
