module GenerateSchemafile
  class Dsl
    class << self
      def make_dsl_string(row)
        return nil unless row.length == 7

        dsl = "\s\s"
        dsl << 't.'
        dsl << convert_invalid_type(row[1])
        dsl << "\s\s"
        dsl << "\"#{row[0]}\""
        dsl << limit(row)
        dsl << "#{null_constraint(row[3])}"
        dsl << default(row)
        dsl << ", array: true" if row[5]
        dsl << comment(row[6])
        dsl
      end

      def default(row)
        value = row[4]
        if !value.nil?
          if row[1] == 'text'
            ''
            # booleanの場合
          elsif %w(true false TRUE FALSE).include?(value.to_s)
            ", default: #{value.downcase}"
            # 数値の場合
          elsif !(value.to_s =~ /^\d+$/).nil?
            ", default: #{value}"
          elsif  value.to_s == '9999-12-31T00:00:00+00:00'
            ", default: '9999-12-31'"
          elsif value.to_s == 'NULL'
            ''
          else
            ", default: '#{value}'"
          end
        else
          ''
        end
      end

      def limit(row)
        if !row[2].nil?
          if row[1] == 'longtext'
            ', limit: 4294967295'
          elsif row[1] == 'bigint'
            ', limit: 8'
          elsif row[1] == 'mediumint'
            ', limit: 3'
          elsif row[1] == 'datetime'
            ''
          else
            ", limit: #{row[2]}"
          end
        else
          ''
        end
      end

      def convert_invalid_type(type)
        case type.strip.downcase
        when 'int', 'smallint', 'mediumint', 'integer'
          'integer'
        when 'bigint', 'long'
          'bigint'
        when 'varchar', 'string'
          'string'
        when 'tinyint'
          'boolean'
        when 'text', 'longtext'
          'text'
        when 'blob'
          'binary'
        when 'datetime', 'date', 'time', 'timestamp', 'boolean', 'float'
          type
        when 'jsonb'
          'jsonb'
        else
          raise "#{type}の型変換ができません"
        end
      end

      def null_constraint(value)
        if value == '◯'
          ', null: false'
        else
          ''
        end
      end

      def comment(value)
        if value.nil?
          ''
        else
          ", comment: \"#{value}\""
        end
      end
    end # Class Methods End
  end
end
