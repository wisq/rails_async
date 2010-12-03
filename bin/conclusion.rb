#!/usr/bin/ruby

class Conclusion  
  def initialize(names)
    @names = names
  end
  
  def run
    @names.each do |name|
      output_log(name, 'out', $stdout, 'output')
      output_log(name, 'err', $stderr, 'errors')
    end

    failed = @names.select { |name| File.exist?("run/#{name}.fail") }
    
    if failed.empty?
      exit(0)
    else
      tasks = failed.map { |name| name_to_task(name, true) }.uniq
      $stderr.puts "Errors running #{to_sentence(tasks)}!"
      exit(1)
    end
  end
  
  private
  
  def output_log(name, type, fh, what)
    file = "log/#{name}.#{type}"
    if File.exist?(file)
      fh.puts('', "=== #{what.capitalize} for #{name_to_task(name)} ===", '')
      fh.puts(File.read(file))
    end
  end
  
  def name_to_task(name, short = false)
    name.gsub('_', ':').sub(/:(\d+):of:(\d+)$/, short ? '' : ' (part \\1 of \\2)')
  end
  
  def to_sentence(list)
    if list.count == 1
      list.first
    elsif list.count == 2
      list.join(' and ')
    else
      last = list.pop
      list.join(', ') + ', and ' + last
    end
  end
end

Conclusion.new(ARGV).run
