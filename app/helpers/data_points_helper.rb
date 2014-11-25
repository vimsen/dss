module DataPointsHelper
  def round_or_null a, i
    a.round(i) unless a.nil?
  end
    
end
