namespace :import do
  desc "Import S+ (splus.ru) report exports from a folder: bin/rails import:splus[/path/to/folder]"
  task :splus, [ :dir ] => :environment do |_, args|
    dir = args[:dir] or abort "Usage: bin/rails import:splus[/path/to/folder]"
    files = Dir[File.join(dir, "*.{csv,CSV,xlsx}")].to_h { |path| [ File.basename(path), File.binread(path) ] }
    tables = Imports::Splus.detect(files)
    puts "Detected: #{tables.keys.join(', ')}"
    result = Imports::Splus.new(tables).run!
    DataImport.create!(kind: "splus", filename: files.keys.join(", "), status: "done", result: result.merge("detected" => tables.keys.map(&:to_s)))
    result["counts"].sort.each { |key, count| puts "  #{key}: #{count}" }
    result["warnings"].each { |warning| puts "  warning: #{warning}" }
  end
end
