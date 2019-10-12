use Mix.Config
config :logger, :console,
  level: :debug,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:module, :function, :file, :line]
