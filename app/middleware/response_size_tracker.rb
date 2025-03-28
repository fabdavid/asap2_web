class ResponseSizeTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response_body = @app.call(env)

    # Calculate total bytes
    body_string = ""
    response_body.each { |part| body_string << part }
    response_size = body_string.bytesize

    # You can extract the current user if you're using Devise/Warden
    user = current_user

    # Log it (to DB or logs)
    Rails.logger.info "User #{user&.id || 'guest'} - #{env['REQUEST_METHOD']} #{env['PATH_INFO']} - #{response_size} bytes"

    # Optionally log to DB
    if user
      ResponseLog.create!(
        user: user,
        path: env["PATH_INFO"],
        method: env["REQUEST_METHOD"],
        bytes_sent: response_size,
        logged_at: Time.current
      )
    end

    [status, headers, [body_string]]
  end
end
