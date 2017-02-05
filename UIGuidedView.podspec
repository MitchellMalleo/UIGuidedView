Pod::Spec.new do |s|
  s.name             = "UIGuidedView"
  s.version          = "0.0.7"
  s.summary          = "A simple control designed for guiding a user through a controlled flow"
  s.homepage         = "https://github.com/MitchellMalleo/UIGuidedView"
  s.license          = 'MIT'
  s.author           = { "Mitch Malleo" => "mitchellmalleo@gmail.com" }
  s.source           = { :git => "https://github.com/MitchellMalleo/UIGuidedView.git", :tag => s.version.to_s }
  s.platform     = :ios, '5.0'
  s.requires_arc = true
  s.source_files = 'Classes', 'Classes/**/*.{h,m}'
end
