# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  config.on(:startup) do
    unless Sidekiq::Cron::Job.find("Run scheduled tests")
      Sidekiq::Cron::Job.create(
        name: "Run scheduled tests",
        cron: "* * * * *",
        class: "RunScheduledTestsJob"
      )
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
