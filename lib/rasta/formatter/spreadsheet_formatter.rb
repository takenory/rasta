# TODO: put name of spreadsheet on the page
# and think about how to handle multiple spreadsheets

Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')
require 'spec/runner/formatter/base_formatter'
require 'xml'
module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        begin; require 'syntax/convertors/html'; @@converter = Syntax::Convertors::HTML.for_syntax "ruby"; rescue LoadError => e; @@converter = NullConverter.new; end
        
        def start(example_count)
          @example_count = example_count
          @total_count = 0
          @total_passed = 0
          @total_failed = 0
          @total_exception = 0
          @total_pending = 0
          @output.puts html_header
          @output.puts html_tabs
          @output.puts html_footer
          @output.flush
          parser = XML::HTMLParser.file(@output.path)
          @doc = parser.parse
        end
        
        def update_totals(name, value)
          @total_count += 1
          @doc.find("//td[@class='total-count']")[0].content = @total_count.to_s
          @doc.find("//td[@class='#{name}']")[0].content = value.to_s
        end  
          
        def update_passed_counts
          update_totals('total-passed', @total_passed += 1)
        end

        def update_failed_counts
          update_totals('total-failed', @total_failed += 1)
        end
        
        def update_pending_counts
          update_totals('total-pending', @total_pending += 1)
        end

        def example_passed(example)
          update_passed_counts
          table_cell = @doc.find("//td[@id='#{@record}']")[0]
          table_cell.attributes['class'] = 'passed'
          @doc.save(@output.path)
        end

        def example_failed(example, counter, failure)
          update_failed_counts
          table_cell = @doc.find("//td[@id='#{@record}']")[0]
          table_cell.attributes['class'] = failure_type(failure)
          add_test_failure_summary(example, failure)
          add_test_failure_tooltip(table_cell, failure)
          @doc.save(@output.path)
        end
        
        def example_pending(example, message)
          update_pending_counts
          table_cell =  @doc.find("//td[@id='#{@record}']")[0]
          table_cell['class'] = 'pending'
          add_test_pending_summary(example, message)
          @doc.save(@output.path)
        end

        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_summary(*args); end
        def dump_pending(*args); end
    
        def add_test_failure_tooltip(table_cell, failure)
          table_cell << span = XML::Node.new('span')
          span << pre = XML::Node.new('pre')
          pre << @record + "\n" + failure_message(failure)
        end
    
        def add_test_pending_summary (example, message)
          summary = @doc.find("//div[@class='summary-errors']")[0] 
          summary << header = XML::Node.new('div')
          header['class'] = 'error-pending-header'
          header << @record + ': ' + example.description
          summary << detail = XML::Node.new('div')
          detail['class'] = 'error-pending-detail'
          detail << pre = XML::Node.new('pre')
          pre << message
        end

        def add_test_failure_summary (example, failure)
          summary = @doc.find("//div[@class='summary-errors']")[0] 
          summary << header = XML::Node.new('div')
          header['class'] = 'error-' + failure_type(failure) + '-header'
          header << @record + ': ' + example.description
          summary << detail = XML::Node.new('div')
          detail['class'] = 'error-' + failure_type(failure) + '-detail'
          detail << pre = XML::Node.new('pre')
          pre << failure_message(failure)
          if failure.exception.backtrace
            summary << exception = XML::Node.new('div')
            exception['class'] = 'error-failed-exception'
            exception << code_snippet(failure) 
          end  
        end
        
        def code_snippet(failure)
          require 'spec/runner/formatter/snippet_extractor'
          @snippet_extractor ||= SnippetExtractor.new
          pre = XML::Node.new('pre') 
          pre['class'] = 'ruby'
          pre << code = XML::Node.new('code') 
          (raw_code, linenum) = @snippet_extractor.snippet_for(failure.exception.backtrace[0])
          raw_code.split("\n").each_with_index do |line, l|
            line = "#{l + linenum - 2}: " + line
            code << line_p = XML::Node.new('p') 
            if l == 2
             line_p['class'] = 'offending' 
            else
              line_p['class'] = 'linenum'
            end
            code << line
          end
          pre
        end
        
        def failure_message(failure)
          failure.exception.backtrace ? failure.exception.message + "\n" + failure.exception.backtrace.join("\n") : failure.exception.message 
        end

        def failure_type(failure)
          failure.exception.backtrace ? 'exception' : 'failed'
        end

        def html_header
          header = <<-EOS
                  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
                  <html lang="en">
                  <head>
                  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"/>
                  <title>Rasta Test Results</title>
                  EOS
          header += html_style + html_javascript      
          header += <<-EOS
                    </head>
                    <body>
                    <div class="tabber">
                    EOS
          header
        end

        # show the spreadsheet in it's entirety
        def html_tabs
          tabs = ''
          current_sheet = @oo.default_sheet
          tabs += html_summary_tab
          tabs += html_errors_tab
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            tabs += "  <div class=\"tabbertab\">\n"
            tabs += "    <h2>#{sheet}</h2>\n"
            tabs += "    #{html_spreadsheet}\n\n"
            tabs += "  </div>\n"
          end
          @oo.default_sheet = current_sheet
          tabs
        end
       
        def html_summary_tab
          @oo.info =~ /File: (\S+)/
          spreadsheet_name = $1 || 'Google Spreadsheet'
          summary = <<-EOS
                      <div class="tabbertab">
                        <div class="summary-counts">
                          <h2>Summary</h2>
                          <table class="summary" summary ="Summary of test results">
                          <tr><td class="summary-title">Filename</td><td class="summary-detail-text">#{spreadsheet_name}</td></tr>
                          <tr><td class="summary-title">Tests Run</td><td class="total-count">0</td></tr>
                          <tr><td class="summary-title">Passed</td><td class="total-passed">0</td></tr>
                          <tr><td class="summary-title">Failed</td><td class="total-failed">0</td></tr>
                          <tr><td class="summary-title">Pending</td><td class="total-pending">0</td></tr>
                          <tr><td class="summary-title">Execution Time</td><td class="total-time">0</td></tr>
                          </table>
                        </div>
                        <br><br>
                      </div>
                    EOS
        end

        def html_errors_tab
          <<-EOS
              <div class="tabbertab">
                <div class="errors">
                  <h2>Errors</h2>
                  <div class="summary-errors"/>
                </div>
              </div>
            EOS
        end
        
        def html_style
#          rasta_css = File.new(File.join(Resource_dir,'rasta.css'))
#          css = "<style TYPE=\"text/css\" MEDIA=\"screen\">\n"
#          css += rasta_css.read
#          css += "</style>\n"
          "<LINK href=\"#{File.join(Resource_dir,'rasta.css')}\" rel=\"stylesheet\" type=\"text/css\">"
        end

        def html_javascript
          #tabber = File.new(File.join(Resource_dir,'tabber-minimized.js'))
          #javascript = "<script TYPE=\"text/javascript\">\n"
          #javascript += tabber.read
          #javascript += "</script>\n"
          "<script src=\"#{File.join(Resource_dir,'tabber-minimized.js')}\"> </script>"
        end

        def html_footer
          <<-EOS
            </div>
            </body>
          </html>
          EOS
        end
        
        def html_spreadsheet
          o=""
          sheet = @oo.default_sheet
          linenumber = @oo.first_row(sheet) 
          o << "<table id=\"#{sheet}\" summary=\"Test results for tab #{sheet}\" border=\"0\" cellspacing=\"1\" cellpadding=\"5\">"
          o << "<tr class=\"column-index\" align=\"center\">"
          o << "<td>&nbsp;</td>"
          records = @oo.records(sheet)
          @oo.first_column(sheet).upto(@oo.last_column(sheet)) {|col| 
            o << "<td class=\"column-index\">#{GenericSpreadsheet.number_to_letter(col)}</td>"
          } 
          o << "</tr>"
          @oo.first_row.upto(@oo.last_row) do |row|
            o << "<tr>"
            o << "<td class=\"row-index\">#{linenumber.to_s}</td>"
            linenumber += 1
            @oo.first_column(sheet).upto(@oo.last_column(sheet)) do |col|
              if (records.type == :column && col == records.header_index) || records.type == :row && row == records.header_index
                td_class = 'header'
              else
                td_class = 'not_run'
              end
              cell = @oo.cell(row,col).to_s
              cell =~ /\A\S+\Z/ ? align = 'align=center' : align = ''
              o << "<td id=\"#{sheet}-#{GenericSpreadsheet.number_to_letter(col)}#{row}\" class=\"#{td_class}\">"
              if cell.empty?
                o << "&nbsp;"
              else
                o << "#{CGI::escapeHTML(@oo.cell(row,col).to_s)}"
              end
              o << "</td>"
            end
            o << "</tr>"
          end
          o << "</table>"
        
          return o
        end
    

      end        
    end
  end
end
