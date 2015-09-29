Gem::Specification.new do |s|
  s.name = "mlock"
  s.version = "0.0.2"
  s.summary = %{Multiple resource locking (shared and exclusive) library for Redis.}
  s.description = %Q{Mlock is a library that allows to lock resources in Redis, a persistent key-value database. Library was designed to syncronize operations in multiprocess/multicomputer environment.}
  s.authors = ["Jakub Zdroik"]
  s.email = ["jakub.zdroik@gmail.com"]
  s.license = "MIT"
  s.homepage = "https://github.com/qbazd/mlock"

  s.files = `git ls-files`.split("\n")

  #s.rubyforge_project = "mlock"

  s.add_dependency "redis", '~> 0'
  s.add_dependency "nido", '~> 0'
  s.add_development_dependency "cutest", '~> 0'
end
