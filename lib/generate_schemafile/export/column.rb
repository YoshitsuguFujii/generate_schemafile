module GenerateSchemafile
  class Export::Column
    def initialize(type, name, options)
      @type = type
      @name = name
      @options = options
    end

    def type
      @type
    end

    def name
      @name
    end

    def options
      @options
    end
  end
end
