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

Either open `index.html` in a browser (no hot-reload) or use npm nutzen (see bellow).

### Install node.js and dependencies

Run only once

* Install node.js
* Run `npm install`

### Start server for hot reload

`npm run start`  

* Starts web server with presentation on http://localhost:8000.
* The command does not return and watches the resources (slides, index, css, js) for changes. Seems not work on Windows.
* Reloads automatically on change (no refreshing necessary in the browser)

# Update reveal.js version

```bash
git remote add reveal https://github.com/hakimel/reveal.js.git 
git pull reveal master
```

Better use merge here, because rebase leads to changed history and no option to reproducte what happend in the past.

# Print slides / create PDF 

## Official / manual

* In Chrome: http://localhost:8000/?print-pdf
* Ctrl + P
* Save As PDF
* Can be customized using a [separate Stylesheet](../css/print/pdf.css)

See [reveal.js README](https://github.com/hakimel/reveal.js/#pdf-export)

Note that [internal links](https://github.com/hakimel/reveal.js/#internal-links) only work in the PDF using the following:

```html
<!-- works -->
<a href="#some-slide">Link</a> 
<!-- doesn't -->
<a href="#/some-slide">Link</a> 
```
## Continuously delivery

* The `Jenkinsfile` automatically creates a PDF on git push.
* The `<title>` of `index.html` is used as file name
* The PDF is attached to the Jenkins job. See `https://<jenkins-url>/job/<job-url>/lastSuccessfulBuild/artifact/`
* It's also deployed with the web-based application. See `https://<your-url>/<title of index.html>.pdf`

Compared to the one manually created there are at least the following differences:

* Video thumbnail not displayed
* Header and footer show "invisible" texts, that can be seen when marking the text
* Backgrounds are also exported (e.g. when using the `cloudogu-black` theme)