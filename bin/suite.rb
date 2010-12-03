#!/usr/bin/ruby

require 'pathname'
require 'fileutils'

class Suite
  BIN_PATH  = Pathname.new(__FILE__).realpath.dirname
  BASE_PATH = BIN_PATH.dirname
  LIB_PATH  = BASE_PATH + 'lib'

  WORK_PATH = Pathname.getwd
  TEST_PATH = WORK_PATH + 'test'
  LOG_PATH  = WORK_PATH + 'log'
  LOCK_PATH = FLAG_PATH = WORK_PATH + 'run'
  
  def initialize(name)
    @name = name

    if name =~ /^test_(.+)_(\d+)_of_(\d+)$/
      @task = [
        'rails_async:test_chunk',
        "CHUNK_SUITE=#{$1}",
        "CHUNK_NUMBER=#{$2}",
        "CHUNK_TOTAL=#{$3}"
      ]
    else
      @task = name.gsub('_', ':')
    end
  end
  
  def run
    tree = select_tree
    setup_flag = setup_flag(tree)

    ENV['RAILS_ASYNC_LIB'] = LIB_PATH
    unless setup_flag.exist?
      run_command("Setup for #{tree}",  tree, [BIN_PATH + 'setup', tree.basename])
      FileUtils.touch(setup_flag)
    end
    run_command("Rake task #{@task}", tree, ['rake', 'rails_async:no_db_clone', @task].flatten)
  end
  
  private
  
  def select_tree
    TEST_PATH.entries.each do |entry|
      next if entry.to_s.start_with?('.')

      path = TEST_PATH + entry
      next unless path.directory? && (path + '.git').directory?
      
      return path if lock_tree(entry.to_s)
    end
    
    raise 'No test trees available'
  end

  def lock_tree(name)
    lockfile = LOCK_PATH + "test_#{name}.lock"
    fh = lockfile.open('w')
    if fh.flock(File::LOCK_EX | File::LOCK_NB)
      @lock = fh
      true
    else
      fh.close
      false
    end
  end

  def run_command(title, tree, command)
    pid = fork do
      # These intentionally overwrite prior (successful) commands' logs.
      $stdout.reopen(task_log('out'))
      $stderr.reopen(task_log('err'))
      $stdin.reopen('/dev/null')

      Dir.chdir(tree)
      exec(*command.map(&:to_s))
      raise 'exec failed'
    end
    
    Process.wait(pid)
    stat = $?
    
    unless stat.success?
      exit(stat.exitstatus) if stat.exited?
      raise "#{title} died with signal #{stat.termsig}" if stat.signaled?
      raise "#{title} died of unknown causes"
    end
  end
  
  def task_log(type)
    LOG_PATH + "#{@name}.#{type}"
  end

  def setup_flag(tree)
    FLAG_PATH + "tree_#{tree.basename}.setup"
  end
end

Suite.new(*ARGV).run
