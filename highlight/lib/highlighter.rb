require 'set'

class Highlighter
  def self.highlight(file_path, patterns_hash)
    in_file = File.new(file_path)
    out_file = File.new(file_path + ".html", "w")

    out_file.write(header(patterns_hash))

    in_file.each_line do |line|
      patterns_hash.each_pair do |pattern, color|
        line.gsub!(Regexp.new(pattern), "<span class=\"color#{color_name(color)}\">\\0</span>")
      end
      out_file.write(line)
    end

    out_file.write(footer)

    out_file.close()
    in_file.close()
  end

  def self.color_name(color)
    color.gsub(/[^a-fA-F0-9]/, "")
  end

  def self.header(patterns_hash)
    colors = Set.new(patterns_hash.values)
    rv = %Q|<style type="text/css">\n|
    colors.each do |color|
      rv << "\t.color#{color_name(color)} { background-color: #{color} }\n"
    end
    rv << "</style>\n"
    rv << "<pre>\n"
  end

  def self.footer()
    return "</pre>\n"
  end
end