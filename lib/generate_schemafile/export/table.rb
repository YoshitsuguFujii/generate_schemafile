module GenerateSchemafile
  class Export::Table
    def initialize(table_name, columns, options)
      @table_name = table_name
      @columns = columns
      @options = options
    end

    def table_name
      @table_name
    end

    def add_index(index)
      @indexes ||= []
      @indexes << index
    end

    def columns
      @columns
    end

    def indexes
      @indexes
    end

    def options
      @options
    end
  end
end
