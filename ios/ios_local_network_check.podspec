Pod::Spec.new do |s|
  s.name             = 'ios_local_network_check'
  s.version          = '0.0.1'
  s.summary          = 'Checks the iOS Local Network permission.'
  s.description      = <<-DESC
Checks the iOS Local Network permission using a caller-provided TCP or UDP endpoint.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ios_local_network_check/Sources/ios_local_network_check/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
