specs_hash = Hash.new { |h,n| h[n] = [] }

open('versions.list') do |io|
  io.each_line do |line|
    name, versions = line.split(' ', 2)
    versions = versions.split(',')
    versions.map! { |v| v.split('-', 2) }
    versions.each { |v| v[1] ||= 'ruby' }
    specs_hash[name].concat versions
  end
end
