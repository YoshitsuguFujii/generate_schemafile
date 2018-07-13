module GenerateSchemafile
  class Console
    # Class Methods
    class << self
      def display_with_arrow(&block)
        arrow_thread = Thread.start do
          arrow_progress = %w(> >> >>>).cycle
          loop do
            print "\r file reading #{sprintf("%-\s3s", arrow_progress.next)}"
            sleep 1
          end
        end

        rtn = block.call
        Thread.kill(arrow_thread)
        rtn
      end

      def progress_bar(i, max = 100)
        i = i.to_f
        max = max.to_f
        i = max if i > max
        percent = i / max * 100.0
        rest_size = 1 + 5 + 1 # space + progress_num + %
        bar_size = 79 - rest_size # (width - 1) - rest_size
        bar_str = '%-*s' % [bar_size, ('#' * (percent * bar_size / 100).to_i)]
        progress_num = '%3.1f' % percent
        print "\r#{bar_str} #{'%5s' % progress_num}%"
      end

      def print_green(str)
        puts "\e[32m#{str}\e[0m"
      end

      def print_red(str)
        puts "\e[31m#{str}\e[0m"
      end

      def print_yellow(str)
        puts "\e[33m#{str}\e[0m"
      end
    end # Class Methods End
  end
end
