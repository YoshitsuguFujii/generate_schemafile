module GenerateSchemafile
  module Refinements
    module StringExtension
      refine String do
        def trim
          gsub(/^\s*|\s*$/, '')
        end
      end
    end
  end
end
