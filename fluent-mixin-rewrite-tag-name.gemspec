# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-mixin-rewrite-tag-name"
  spec.version       = "0.0.2"
  spec.authors       = ["Kentaro Yoshida"]
  spec.email         = ["y.ken.studio@gmail.com"]
  spec.summary       = %q{Fluentd mixin plugin to provides placeholder function for rewriting tag for your any plugins as like fluent-plugin-rewrite-tag-filter. It will let you get easy to implement tag placeholder for your own plugins.}
  spec.homepage      = "https://github.com/y-ken/fluent-mixin-rewrite-tag-name"
  spec.license       = "Apache License, Version 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "fluentd"
end
