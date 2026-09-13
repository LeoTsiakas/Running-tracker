// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import moment from "moment"
window.moment = moment

// Fill the hidden time zone field on the sign up / edit profile forms with the
// browser's zone. Listens for turbo:load so it also runs on Turbo navigations.
document.addEventListener("turbo:load", () => {
  const field = document.getElementById('user_time_zone')

  if (field) field.value = jstz.determine().name()
})
