class Formulary

  class << self
    alias_method :original_factory, :factory
  end

  def self.core_path(name)
    Repository.main.extend(RepositoryImport).find_formula name
  end

  def self.factory(ref)
    path = nil
    repo = @repositories.detect do |repo|
      repo.extend RepositoryImport
      path = repo.find_formula ref
    end
    original_factory(path.nil? ? ref : File.join(repo.path, path))
  end

  def self.repositories=(repositories)
    @repositories = repositories
  end

end
