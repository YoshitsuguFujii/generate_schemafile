require "generate_schemafile/version"
require "generate_schemafile/refinements/string_extension"
require "generate_schemafile/console"
require "generate_schemafile/dsl"
require "generate_schemafile/export"
require "generate_schemafile/export/table"
require "generate_schemafile/export/column"
require "generate_schemafile/export/index"
require "generate_schemafile/excel/style"

require 'rubyXL'
require 'axlsx'

# bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile
module GenerateSchemafile
  class InvalidFormatError < StandardError; end

  COL_INFO = {
    array: {col_num: 10},
    index: {col_num: 11..20},
    foreign_key: {col_num: 21},
    unsighted: {col_num: 22},
    comment: {col_num: 23}
  }

def show_help
Console.print_yellow <<"HELP_MES"
Usage:
## ExcelからSchemafileを作成する
$ bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile

Options:
  --file_path   : DB定義書までの場所を指定(default: DB設計書.xlsm)
  --output_path : Schemafileの出力場所を指定(default: ./Schemafile)
  --help        : this help

## Excelに出力する
$ bundle exec generate_schemafile --export --file_path db/Schemafile --output_path doc/DB設計書.xlsx
HELP_MES
end

def export(params)
  Export.export(params)
end

def invoke(params)
  if params['help']
    show_help
    exit
  end

  if params['export']
    export(params)
    exit
  end

  # ファイル存在チェック
  unless File.exist?(params['file_path'])
    Console.print_red("#{params['file_path']} is not found")
    exit
  end

  schema_str = ''
  foreign_key_str = ''
  workbook = Console.display_with_arrow do
    RubyXL::Parser.parse(params['file_path'])
  end

  all_sheet = workbook.worksheets.count
  workbook.worksheets.each.with_index(1) do |sheet, idx|
    Console.progress_bar(idx / all_sheet * 100)

    next if %w(更新履歴 一覧).include?(sheet.sheet_name)
    next if sheet.sheet_name.gsub(/\s/,'').downcase.start_with?('skipexport')
    next unless sheet[1][0].value == 'テーブル定義書'

    table_name = sheet[5][2].value if sheet[5][1].value == '物理名称'

    table_jp_name = sheet[4][2].value if sheet[4][1].value == 'テーブル名'

    option =  if !sheet[1][21].nil? && sheet[1][21].value == 'オプション' && !sheet[1][23].value.nil? && !sheet[1][23].value.empty?
                sheet[1][23].value
              else
                nil
              end

    next if table_name == 'schema_migrations' || table_name.to_s == ''

    foreign_keys = []
    columns = []
    tbl_idx    = []
    u_tbl_idx    = []
    ud_tbl_idx    = []

    COL_INFO[:index][:col_num].size.times do |i|
      tbl_idx[i] = []
      u_tbl_idx[i] = []
      ud_tbl_idx[i] = []
    end

    id_value = 'false'
    row_num = 9 # set start row number
    while sheet[row_num] && !sheet[row_num][2].value.nil?
      row = []

      # 以下はrailsで自動生成するので不要
      if %w(id).include?(sheet[row_num][2].value.strip)
        if sheet[row_num][3].value.strip == 'bigint'
          id_value = ''
        else
          id_value = ':integer'
        end
        row_num += 1
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

      row << (sheet[row_num][COL_INFO[:array][:col_num]]&.value rescue nil)        # array
      row << (sheet[row_num][COL_INFO[:unsighted][:col_num]]&.value rescue nil)    # unsighted
      row << (sheet[row_num][COL_INFO[:comment][:col_num]]&.value rescue nil)      # コメント

      foreign_keys << (sheet[row_num][COL_INFO[:foreign_key][:col_num]]&.value rescue nil)  # 外部キー制約

      # index
      COL_INFO[:index][:col_num].each_with_index do |col_num, i|
        tbl_idx[i] << [sheet[row_num][2].value.strip, sheet[row_num][col_num].value.to_s.strip] if !sheet[row_num][col_num].value.nil? && sheet[row_num][col_num].value.to_s =~ /^\d+$/ # index
      end

      # uniq index
      COL_INFO[:index][:col_num].each_with_index do |col_num, i|
        u_tbl_idx[i] << sheet[row_num][2].value.strip  if sheet[row_num][col_num].value == 'u'
      end

      # uniq indx without soft deleted
      COL_INFO[:index][:col_num].each_with_index do |col_num, i|
        ud_tbl_idx[i] << sheet[row_num][2].value.strip  if sheet[row_num][col_num].value == 'ud'
      end

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
    schema_str << "create_table '#{table_name}' #{ ', id: ' + id_value unless id_value.empty?}, force: :cascase#{", options: \"#{option}\""if option} do |t|\n"
    schema_str << columns.join("\n")
    schema_str << "\n"
    schema_str << "end\n"

    foreign_keys.compact!
    foreign_keys.each do |key|

      fk_option = key.scan(/\[(.*)\]/).first.first rescue ''
      key = key.gsub("[#{fk_option}]", '') unless fk_option.empty?
      keys = key.split('.')

      foreign_key_str <<  "add_foreign_key '#{table_name}', '#{keys[0]}'"
      foreign_key_str <<  ", column: '#{keys[1]}'" unless keys[1].nil?
      foreign_key_str <<  ", #{fk_option}" unless fk_option.empty?
      foreign_key_str <<  "\n"
    end

    schema_str << "\n"

    tbl_idx.each do |idx|
      unless idx.empty?
        idx.sort! { |a, b| a[1] <=> b[1] }
        index_name = "idx_#{idx.map(&:first).join('_')}_to_#{table_name}"[0..62]
        schema_str << "add_index '#{table_name}', #{idx.map(&:first)}, name: '#{index_name}', using: :btree"
        schema_str << "\n"
        schema_str << "\n"
      end
    end

    u_tbl_idx.each do |idx|
      unless idx.empty?
        index_name = "uniq_#{table_name}_#{idx.join('_')}"[0..62]
        schema_str << "add_index '#{table_name}', #{idx}, name: '#{index_name}', unique: true, using: :btree"
        schema_str << "\n"
        schema_str << "\n"
      end
    end

    ud_tbl_idx.each do |idx|
      unless idx.empty?
        index_name = "uniq_#{table_name}_#{idx.join('_')}"[0..62]
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
  schema_str = "# encoding: utf-8\n\n" + schema_str
  f << schema_str
  f << foreign_key_str
  f.close

  Console.print_green("\nDone.")
end

module_function :invoke
module_function :show_help
module_function :export
end
