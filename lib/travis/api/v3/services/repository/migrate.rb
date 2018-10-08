module Travis::API::V3
  class Services::Repository::Migrate < Service
    # FIXME: This shouldn't be "bar" - we need confirmation on what the topic
    #   should be for beginning the migration
    #
    KAFKA_TOPIC = "essential.repository.migrate"

    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)

      if admin = access_control.admin_for(repository)
        Travis::Kafka.deliver_message(
          topic: KAFKA_TOPIC,
          msg: {
            data:     { owner_name: admin.login, name: repository.name },
            metadata: { force_reimport: false }
          },
        )

        Travis.logger.info(
          "Repo Migration Request: Repo ID: #{repository.id}, User: #{admin.id}"
        )

        result repository
      end
    rescue Kafka::Error => e
      Travis.logger.error(
        "Repo Migration Request Failed -- Exception: #{e.class}, " +
          "Repo ID: #{repository.id}, Repo slug: #{repository.slug}, " +
          "User: #{admin.id}"
      )

      raise e
    end

    private

    def check_access(repository)
      access_control.permissions(repository).migrate!
    end
  end
end
