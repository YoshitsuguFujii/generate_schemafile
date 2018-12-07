module GenerateSchemafile
  class Export
    using GenerateSchemafile::Refinements::StringExtension

    class << self
      def export(params)
        unless File.exist?(params['file_path'])
          Console.print_red("#{params['file_path']} is not found")
          exit
        end

        file = File.new(params['file_path']).read
        tables = extract_table(file)
        indexes = extract_index(file)


        indexes.each do |index|
          table = tables.detect{|t| t.table_name == index.table_name}
          table.add_index(index)
        end

        pkg = Axlsx::Package.new
        pkg.use_shared_strings = true
        workbook = pkg.workbook
        workbook.styles.fonts.first.name = 'MS Pゴシック'
        default_style = GenerateSchemafile::Excel::Style.default_cell_style(workbook)
        green_cell_style = GenerateSchemafile::Excel::Style.default_cell_style(workbook, {bg_color: "caf9cc", alignment: {horizontal: :center, vertical: :center, wrap_text: true}})
        tables.each do |table|
          workbook.add_worksheet(name: table.table_name) do |ws|
            ws.add_row []
            ws.add_row ['テーブル定義書', nil, 'システム名', nil], style: default_style
            ws.add_row [nil, nil, 'データ種別', ''], style: default_style
            ws.merge_cells("A2:B3")
            ws.rows[1].cells[0].style = green_cell_style

            ws.add_row []

            ws.add_row [nil, 'テーブル名', nil], style: default_style
            ws.rows.last.cells[0].style = green_cell_style
            ws.rows.last.cells[1].style = green_cell_style
            ws.add_row [nil, '物理名称', table.table_name], style: default_style
            ws.rows.last.cells[0].style = green_cell_style
            ws.rows.last.cells[1].style = green_cell_style
            ws.add_row [nil, 'テーブル概要説明', nil], style: default_style
            ws.rows.last.cells[0].style = green_cell_style
            ws.rows.last.cells[1].style = green_cell_style

            ws.add_row []

            ws.add_row ['No.', '名称', 'フィールド名', '型', '桁数', 'PK', 'AUTO_ INCREMENT', 'UNSIGNED',
                        'Not Null', 'デフォルト', 'array', 'index', nil, nil, nil, nil, nil, nil, nil, nil, nil, '備考', nil, nil, nil], style: green_cell_style

            ws.merge_cells("L9:U9")
            ws.merge_cells("V9:Y9")
            ws.add_comment ref: 'F9', text: '未使用', author: '', visible: false
            ws.add_comment ref: 'G9', text: '未使用', author: '', visible: false
            ws.add_comment ref: 'H9', text: '未使用', author: '', visible: false
            ws.add_comment ref: 'I9', text: '○をつける', author: '', visible: false
            ws.add_comment ref: 'J9', text: 'デフォルト値を入力してください。boleanの場合はセルの表示形式を文字列にしてください。', author: '', visible: false
            ws.add_comment ref: 'K9', text: '○をつける', author: '', visible: false
            ws.add_comment ref: 'L9', text: "Indexにをはりたい順番に数値を入力してください\nユニークキーはuと入力\n削除済を除く場合はudと入力", author: '', visible: false

            table.columns.each.with_index(1) do |column, idx|
              column_indexes = Array.new(table.indexes&.size.to_i)
              if table.indexes
                table.indexes.each_with_index do |index, idx|
                  next unless index.columns.include?(column.name)
                  if index.options[:where]
                    column_indexes[idx] = 'ud'
                  elsif index.options[:uniq]
                    column_indexes[idx] = 'u'
                  else
                    column_indexes[idx] = index.columns.index(column.name) + 1
                  end
                end
              end
              column_indexes.fill(nil, column_indexes.size..9)

              ws.add_row(
                [
                  idx,
                  nil,
                  column.name,
                  column.type,
                  column.options['limit'],
                  nil,
                  nil,
                  nil,
                  column.options['null'] == 'false' ? '◯' : '',
                  column.options['default'],
                  column.options['array']
                ].concat(column_indexes).concat(Array.new(4, nil)),
                style: default_style
              )
              ws.merge_cells(ws.rows.last.cells[21..25])
            end

            # 列幅調整
            ws.column_info[0].width = 4
            ws.column_info[1].width = 25
            ws.column_info[2].width = 27
            ws.column_info[3].width = 10
            [*4..20].each do |idx|
              ws.column_info[idx].width = 4
            end
          end
        end
        pkg.serialize(params['output_path'])
      end

      def extract_table(file)
        tables = []
        file.scan(/^create_table.*?^end{1}/im).each do |table_str|
          columns = []
          table_options = {}

          table_name = table_str.scan(/create_table(.*),/).flatten.first.split(',')[0].gsub(/\s|"|'/, '')
          if !table_str.split("\n")[0].gsub(/\s/, '').downcase.include?('id:false')
            columns << Column.new('int', 'id', {'limit' => 11, 'null' => false})
          end

          table_str.split("\n").each do |field|
            next if field.start_with?('create_table') || field.start_with?('end')
            field = field.trim # 行頭と行末のスペースを削除
            fields = field.split("\s")
            type= fields[0].split('.')[1]
            column_name = fields[1].gsub(/"|,|'/, '')
            leftovers = field.scan(Regexp.new("#{fields[0]}\s*#{fields[1]}\s*(.*)")).flatten.first
            leftovers = leftovers.split('#').first

            column_options = {}
            leftovers.to_s.split(',').each do |option|
              option = option.trim

              key = option.split(':').first.trim
              value = option.gsub("#{key}:", '').trim

              hash = { key => value }
              hash.delete('default') if hash['default']  == '""'
              column_options.merge!(hash)
            end
            columns << Column.new(type, column_name, column_options)
          end

          tables << Table.new(table_name, columns, table_options)
        end
        tables
      end

      def extract_index(file)
        indexes =[]
        file.scan(/^add_index.*?$/i).each do |field|
          options = {}
          field = field.trim
          table_name = field.split("\s")[1].gsub(/"|,|'/, '').gsub(':', '')

          columns = if field.scan(/\[.*\]/).empty?
                      [field.split(',')[1].trim.gsub(/:/,'')]
                    else
                      field.scan(/\[.*\]/).first.gsub(/\[|\]|"/, '').split(',').map(&:trim)
                    end

          options[:uniq] = field.gsub(/\s/, '').include?('unique:true')
          options[:where] = field.gsub(/\s/, '').include?('where:') && field.gsub(/\s/, '').downcase.include?('deleted_atisnull')
          indexes << Index.new(table_name, columns, options)
        end
        indexes
      end
    end
  end
end
