specs = Marshal.load(File.read('specs.4.8'))
spec_hash = Hash.new { |h,n| h[n] = [] }
specs.each do |n,v,p|
  spec_hash[n] << [v,p]
end
