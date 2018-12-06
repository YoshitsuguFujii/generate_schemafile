module GenerateSchemafile
  class Export::Index
    def initialize(table_name, columns, options)
      @table_name = table_name
      @columns = columns
      @options = options
    end

    def table_name
      @table_name
    end

    def columns
      @columns
    end

    def options
      @options
    end
  end
end
