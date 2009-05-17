module Rasta

  class BookmarkError < RuntimeError; end
  
  class Bookmark
    attr_accessor :page_count, :max_page_count
    attr_accessor :record_count, :max_record_count, :continue

    def initialize
      @continue = false
      @page_count = 0
      @record_count = 0
      @max_page_count = Roo::Spreadsheet::options[:pages] || 0
      @max_record_count = Roo::Spreadsheet::options[:records] || 0
      read
    end
  
    def found_page?(page)
      return true if @found_bookmark_page
      @found_bookmark_page = true if page == @bookmark_page 
      @found_bookmark_page || false
    end
  
    def found_record?(record)
      return true if @found_bookmark_record 
      @found_bookmark_record = true if record == @bookmark_record
      @found_bookmark_record || false
    end
  
    def exceeded_max_records?
      return false if @max_record_count == 0 and @max_page_count == 0
      return true if (@record_count > @max_record_count) and @max_record_count > 0
      return true if (@page_count > @max_page_count) and @max_page_count > 0
      return false
    end

    def read
      if Roo::Spreadsheet::options[:continue]
        @continue = true 
        @bookmark_page, @bookmark_record = parse_bookmark(Roo::Spreadsheet::options[:continue])
        @found_bookmark_record = true unless @bookmark_record
      else
        @found_bookmark_page = true
        @found_bookmark_record = true
      end  
    end

    def parse_bookmark(name)
      valid_bookmark_format = /^([^\[]+)(\[(\S+)\])?/
      column_record = /\A[a-z]+\Z/i 
      row_record = /\A\d+\Z/ 
      return [nil,nil] if name.nil?
      if name =~ valid_bookmark_format
        pagename = $1
        record = $3
        case record
        when column_record
          record = GenericSpreadsheet.letter_to_number(record)
        when row_record  
          record = record.to_i
        when nil
          # no record set, which is fine
        else
          raise BookmarkError, "Invalid record name for bookmark '#{name}'" 
        end   
        return pagename, record
      else
        raise BookmarkError, "Invalid bookmark name '#{name}'" 
      end  
    end
  end
end