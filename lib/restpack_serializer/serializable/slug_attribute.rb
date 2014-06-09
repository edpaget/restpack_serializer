module RestPack::Serializer::SlugAttribute
  extend ActiveSupport::Concern

  module ClassMethods
    #def slug_attribute
      #@slug_attribute
    #end

    def slug_attribute(attr)
      @slug_attribute(attr)
    end

  end
end
