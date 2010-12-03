class TestChunk
  def self.file_size(file)
    @@sizes ||= Hash.new { |h, k| h[k] = File.stat(k).size }
    @@sizes[file]
  end

  def self.sort_files(files)
    files.sort_by { |file| [1 - file_size(file), file] }
  end

  def self.split_files(count, pattern)
    files = FileList[pattern]
    chunks = (1..count).map { |num| new(num) }

    sort_files(files).each do |file|
      chunks.sort_by {|c| c.sort_key}.first << file
    end
    
    chunks
  end

  def self.files_for_chunk(num, total, pattern)
    split_files(total, pattern)[num - 1].files
  end

  attr_reader :files

  def initialize(num)
    @number = num
    @files  = []
    @total_size = 0
  end

  def <<(file)
    @files << file
    @total_size += self.class.file_size(file)
  end

  def sort_key
    [@total_size, @files.count, @number]
  end
end

SPECIAL_CHUNKS = {
  'api_json' => lambda do |t|
    t.pattern = 'test/api/**/*_test.rb'
    t.ruby_opts << ['-rubygems',  '-rtest/invoke_json_tests']
  end
}

namespace :rails_async do
  task :no_db_clone do
    task = Rake::Task['db:test:prepare']
    task.clear_actions
    task.clear_prerequisites
  end

  task :test_chunk do
    missing = ['CHUNK_SUITE', 'CHUNK_NUMBER', 'CHUNK_TOTAL'] - ENV.keys
    raise "Missing parameters #{missing.to_sentence}" unless missing.empty?

    suite = ENV['CHUNK_SUITE']
    num   = ENV['CHUNK_NUMBER'].to_i
    total = ENV['CHUNK_TOTAL'].to_i

    name = "test_#{suite}_#{num}_of_#{total}"

    Rake::TestTask.new(name) do |t|
      special = SPECIAL_CHUNKS[suite]
      special.call(t) if special

      pattern = t.pattern || "test/#{suite.singularize}/**/*_test.rb"
      t.test_files = TestChunk.files_for_chunk(num, total, pattern)
      t.pattern = nil

      t.libs << 'test'
      t.verbose = true
    end

    Rake::Task[name].invoke
  end
end
