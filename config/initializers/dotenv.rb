# frozen_string_literal: true

# Ensure gitignored .env values win over empty placeholder ENV vars that some
# shells/IDEs inject (dotenv does not overwrite existing keys by default).
if defined?(Dotenv) && Rails.root.join(".env").exist? && !Rails.env.production?
  Dotenv.overwrite(Rails.root.join(".env"))
end
