Gem::Specification.new do |s|
  s.name              = "resque-unique"
  s.version           = "0.1.0"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Resque plugin to ensure only one instance of a job exists in a queue."
  s.homepage          = "http://github.com/ronny/resque-unique"
  s.email             = "ronny@haryan.to"
  s.authors           = [ "Ronny Haryanto", "Chris Wanstrath", "Ray Krueger" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.description       = <<desc
A Resque plugin. If you want only one instance of your job
queued at a time, extend it with this module.

For example:

    class UpdateNetworkGraph
      extend Resque::Plugins::Unique

      def self.perform(repo_id)
        heavy_lifting
      end
    end
desc
end
