// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener( "DOMContentLoaded", () => {
  document.getElementById('user_time_zone').value = jstz.determine().name()
})
