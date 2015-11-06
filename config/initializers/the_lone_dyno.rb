class DataDump < ActiveRecord::Base
end

if ENV['AWS_ACCESS_KEY_ID']

  TheLoneDyno.exclusive do |signal|
    puts "Running on DYNO: #{ENV['DYNO']}"

    require 'objspace'
    require 'tempfile'

    ObjectSpace.trace_object_allocations_start
    signal.watch do |payload|
      puts "Got signal #{payload}"
      Tempfile.open("heap.dump") do |f|


        ObjectSpace.dump_all(output: f)
        f.close

        s3 = Aws::S3::Client.new(region: 'us-east-1')
        File.open(f, 'rb') do |file|
          s3.put_object(body: file, key: "#{Time.now.iso8601}-process:#{Process.pid}-heap.dump", bucket: "heap-dumps-schneems")
        end
      end
    end
  end
end


