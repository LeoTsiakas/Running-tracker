# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'moment' # @2.30.1
pin 'chart.js', to: 'https://ga.jspm.io/npm:chart.js@4.5.1/dist/chart.js' # @4.5.1
pin '@kurkle/color', to: '@kurkle--color.js' # @0.3.4
