module GenerateSchemafile
  module Excel
    class Style
      HEADER_COLOR = "EEFFEE"
      HEADER_FONT_SIZE = 12
      FONT_NAME = "ＭＳ Ｐゴシック"

      BODY_FONT_SIZE = 12

      WIDTH_MULTIPLICATION_FOR_CALC = 3.5

      class << self
        def hearder_style(workbook)
          workbook.styles.add_style(
            bg_color: HEADER_COLOR, sz: HEADER_FONT_SIZE, font_name: FONT_NAME,
            alignment: {horizontal: :left}, border: Axlsx::STYLE_THIN_BORDER)
        end

        def default_cell_style(workbook, options ={})
          workbook.styles.add_style(
            {
              sz: HEADER_FONT_SIZE,
              font_name: FONT_NAME,
              alignment: {horizontal: :left},
              border: Axlsx::STYLE_THIN_BORDER
            }.merge(options)
          )
        end
      end
    end
  end
end
