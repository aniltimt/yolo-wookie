module Cloudmade
  class MalformedResponse < StandardError
  end

  class ServiceUnavailable < StandardError
  end

  class TourTooBig < StandardError
  end

  class RoutesUnavailable < StandardError
  end

  class TilesUnavailable < StandardError
  end

  class PoiAbsentInPrerouting < StandardError
  end
end
