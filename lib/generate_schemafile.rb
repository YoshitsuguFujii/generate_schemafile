require "generate_schemafile/version"
require "generate_schemafile/console"
require "generate_schemafile/dsl"

require 'rubyXL'

# bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile
module GenerateSchemafile
  class InvalidFormatError < StandardError; end

def show_help
Console.print_yellow <<"HELP_MES"
Usage:
$ bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile

Options:
  --file_path   : DB定義書までの場所を指定(default: DB設計書.xlsm)
  --output_path : Schemafileの出力場所を指定(default: ./Schemafile)
  --help        : this help
HELP_MES
end

  def invoke(params)
    if params['help']
      show_help
      exit
    end

    # ファイル存在チェック
    unless File.exist?(params['file_path'])
      Console.print_red("#{params['file_path']} is not found")
      exit
    end

    schema_str = ''
    workbook = Console.display_with_arrow do
      RubyXL::Parser.parse(params['file_path'])
    end

    all_sheet = workbook.worksheets.count
    workbook.worksheets.each.with_index(1) do |sheet, idx|
      Console.progress_bar(idx / all_sheet * 100)

      next if %w(更新履歴 一覧).include?(sheet.sheet_name)
      next unless sheet[1][0].value == 'テーブル定義書'

      table_name = sheet[5][2].value if sheet[5][1].value == '物理名称'

      table_jp_name = sheet[4][2].value if sheet[4][1].value == 'テーブル名'

      next if table_name == 'schema_migrations' || table_name.to_s == ''

      columns = []
      tbl_idx    = []
      tbl_idx[0] = []
      tbl_idx[1] = []
      tbl_idx[2] = []

      u_tbl_idx    = []
      u_tbl_idx[0] = []
      u_tbl_idx[1] = []
      u_tbl_idx[2] = []

      ud_tbl_idx    = []
      ud_tbl_idx[0] = []
      ud_tbl_idx[1] = []
      ud_tbl_idx[2] = []

      has_id = false
      row_num = 9 # set start row number
      while sheet[row_num] && !sheet[row_num][2].value.nil?
        row = []

        # 以下はrailsで自動生成するので不要
        if %w(id).include?(sheet[row_num][2].value.strip)
          row_num += 1
          has_id = true
          next
        end

        row << sheet[row_num][2].value.strip # フィールド名
        row << sheet[row_num][3].value.strip # 型
        row << sheet[row_num][4].value       # 桁数
        row << sheet[row_num][8].value       # not null
        row << if sheet[row_num][9].nil?
                 nil
        else
          sheet[row_num][9].value # デフォルト値
        end
        row << (sheet[row_num][13].try(:value) rescue nil)      # コメント

        # index
        tbl_idx[0] << [sheet[row_num][2].value.strip, sheet[row_num][10].value.to_s.strip] if !sheet[row_num][10].value.nil? && sheet[row_num][10].value.to_s =~ /^\d+$/ # index
        tbl_idx[1] << [sheet[row_num][2].value.strip, sheet[row_num][11].value.to_s.strip] if !sheet[row_num][11].value.nil? && sheet[row_num][10].value.to_s =~ /^\d+$/ # index
        tbl_idx[2] << [sheet[row_num][2].value.strip, sheet[row_num][12].value.to_s.strip] if !sheet[row_num][12].value.nil? && sheet[row_num][10].value.to_s =~ /^\d+$/ # index
        u_tbl_idx[0] << sheet[row_num][2].value.strip  if sheet[row_num][10].value == 'u'     # unique index
        u_tbl_idx[1] << sheet[row_num][2].value.strip  if sheet[row_num][11].value == 'u'     # unique index
        u_tbl_idx[2] << sheet[row_num][2].value.strip  if sheet[row_num][12].value == 'u'     # unique index
        ud_tbl_idx[0] << sheet[row_num][2].value.strip  if sheet[row_num][10].value == 'ud'     # unique index without soft deleted
        ud_tbl_idx[1] << sheet[row_num][2].value.strip  if sheet[row_num][11].value == 'ud'     # unique index without soft deleted
        ud_tbl_idx[2] << sheet[row_num][2].value.strip  if sheet[row_num][12].value == 'ud'     # unique index without soft deleted

        if dsl_str = Dsl.make_dsl_string(row)
          columns << dsl_str
        else
          p sheet.sheet_name
          p row_num
          raise InvalidFormatError
        end

        row_num += 1
      end

      schema_str << "# #{table_jp_name}\n"
      schema_str << "create_table '#{table_name}' #{ ', id: false' unless has_id}, force: :cascase do |t|\n"
      schema_str << columns.join("\n")
      schema_str << "\n"
      schema_str << "end\n"
      schema_str << "\n"

      tbl_idx.each do |idx|
        unless idx.empty?
          idx.sort! { |a, b| a[1] <=> b[1] }
          schema_str << "add_index '#{table_name}', #{idx.map(&:first)}, name: 'idx_#{idx.map(&:first).join('_')}_to_#{table_name}', using: :btree"
          schema_str << "\n"
          schema_str << "\n"
        end
      end

      u_tbl_idx.each do |idx|
        unless idx.empty?
          index_name = "uniq_#{idx.join('_')}"[0..62]
          schema_str << "add_index '#{table_name}', #{idx}, name: '#{index_name}', unique: true, using: :btree"
          schema_str << "\n"
          schema_str << "\n"
        end
      end

      ud_tbl_idx.each do |idx|
        unless idx.empty?
          index_name = "uniq_#{idx.join('_')}"[0..62]
          schema_str << "add_index '#{table_name}', #{idx}, name: '#{index_name}', unique: true, using: :btree, where: '(deleted_at IS NULL)'"
          schema_str << "\n"
          schema_str << "\n"
        end
      end
    end

    f = File.new(params['output_path'], 'w')
    if !params['require'].nil?  && params['require'].length > 0
      params['require'].split(',').each do |require|
        schema_str = "require '#{require}'\n" + schema_str
      end
      schema_str = schema_str + "\n\n"
    end
    f << schema_str
    f.close

    Console.print_green("\nDone.")
  end

  module_function :invoke
  module_function :show_help
end
