# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "method_source"
  s.version = "0.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2012-10-17"
  s.description = "retrieve the sourcecode for a method"
  s.email = "jrmair@gmail.com"
  s.files = [".gemtest", ".travis.yml", ".yardopts", "Gemfile", "LICENSE", "README.markdown", "Rakefile", "lib/method_source.rb", "lib/method_source/code_helpers.rb", "lib/method_source/source_location.rb", "lib/method_source/version.rb", "method_source.gemspec", "test/test.rb", "test/test_code_helpers.rb", "test/test_helper.rb"]
  s.homepage = "http://banisterfiend.wordpress.com"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "retrieve the sourcecode for a method"
  s.test_files = ["test/test.rb", "test/test_code_helpers.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
      # Under some versions of Rubinius, when the tests are run with
      # `bundle exec rake`, the irb tests failes with:
      #     rubysl-irb is not part of the bundle. Add it to Gemfile.
      # This seems to be a bug in some version of Rubinius:
      #     https://gitter.im/rubinius/rubinius/archives/2015/04/14
      # Since this is only a development dependency, we can get away
      # with the the condition.
      if Object.const_defined?("RUBY_ENGINE") && RUBY_ENGINE == 'rbx'
        s.add_development_dependency(%q<rubysl-irb>)
      end
    else
      s.add_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<bacon>, ["~> 1.1.0"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
  end
end
