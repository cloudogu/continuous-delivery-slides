# Wiki

You can find the presentation slides in the `slides` folder.

# Presentation

Realised using [reveal.js](https://github.com/hakimel/reveal.js/).

## Hotkeys

* `S` show Speaker Notes 
* `?` show all Hotkeys 
* `Esc` show slide overview ("grid")
* Cursors: Navigation (on slides "grid")
* `Space` next slide

See also [reveal.js wiki](https://github.com/hakimel/reveal.js/wiki/Keyboard-Shortcuts).

## Run locally

Either open `index.html` in a browser (no hot-reload) or use yarn/npm nutzen (see bellow).

### Install yarn and dependencies

Run only once

* Install `yarn` (also possible via npm, but deprecated)
* Run `yarn install`

### Start server for hot reload

`yarn start`  

* Starts web server with presentation on http://localhost:8000.
* The command does not return and watches the resources (slides, index, css, js) for changes. Seems not work on Windows.
* Reloads automatically on change (no refreshing necessary in the browser)

# Print slides / create PDF 

## Official

* In Chrome: http://localhost:8000/?print-pdf
* Ctrl + P
* Save As PDF
* Can be customized using a [separate Stylesheet](../css/print/pdf.css)

See [reveal.js README](https://github.com/hakimel/reveal.js/#pdf-export)

## An approach for automation

With headless Chrome (e.g. in Docker Container): 

`chromium-browser --headless --disable-gpu --virtual-time-budget=1000 --print-to-pdf=cd-slides-example.pdf "http://localhost:8000/?print-pdf"`  

(works with Chromium 63.0.3239.132)  
See also https://github.com/cognitom/paper-css/issues/13