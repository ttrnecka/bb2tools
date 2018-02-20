require 'fileutils'

ROOT = File.expand_path(File.dirname(__FILE__))
CFG_FILE = File.join(ROOT,"config","config.yml")

def create_dir(dirname)
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end