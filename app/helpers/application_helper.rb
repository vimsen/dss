module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ?
      (sort_direction == "asc")?
        "fa fa-arrow-up"
      : "fa fa-arrow-down"
    : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to "<i class='#{css_class}'></i>#{title}".html_safe, {sort: column, direction: direction, category: params[:category]}
  end

  def setActiveMenuItem(menuItem)
    if request.fullpath.include? menuItem
      'class="active"'
    end
  end

end
