# -*- encoding: utf-8 -*-
# stub: activerecord-redshift-adapter 0.9.12 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-redshift-adapter".freeze
  s.version = "0.9.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Keith Gabryelski".freeze]
  s.date = "2014-03-30"
  s.description = "This gem provides the Rails 3 with database adapter for AWS RedShift.".freeze
  s.email = "keith@fiksu.com".freeze
  s.files = [".gitignore".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "activerecord-redshift-adapter.gemspec".freeze, "lib/active_record/connection_adapters/redshift_adapter.rb".freeze, "lib/activerecord_redshift/table_manager.rb".freeze, "lib/activerecord_redshift_adapter.rb".freeze, "lib/activerecord_redshift_adapter/version.rb".freeze, "lib/monkeypatch_activerecord.rb".freeze, "lib/monkeypatch_arel.rb".freeze, "spec/active_record/base_spec.rb".freeze, "spec/active_record/connection_adapters/redshift_adapter_spec.rb".freeze, "spec/dummy/config/database.example.yml".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "http://github.com/fiksu/activerecord-redshift-adapter".freeze
  s.licenses = ["New BSD License".freeze]
  s.rubygems_version = "2.6.14".freeze
  s.summary = "Rails 3 database adapter support for AWS RedShift.".freeze

  s.installed_by_version = "2.6.14" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<pg>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 3.0.0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
      s.add_runtime_dependency(%q<arel>.freeze, [">= 3.0.0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<pg>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 3.0.0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
      s.add_dependency(%q<arel>.freeze, [">= 3.0.0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<pg>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<arel>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
