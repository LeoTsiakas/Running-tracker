class ApplicationMailer < ActionMailer::Base
  default from: 'Running Tracker <no-reply@running-tracker.local>'
  layout 'mailer'
end
