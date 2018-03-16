# continuous-delivery-slides-example

Web-based presentation that features

* reveal.js with example slides in markdown,
* Jenkins continuous delivery pipeline that deploys to Nexus repo and Kubernetes,
* Cloudogu corporate design via CSS

When using this with a Cloudogu Ecosystem, you can edit slides conveniently from
[Smeagol](https://github.com/cloudogu/smeagol).

Combined with a Jenkins Job, every save action in Smeagol triggers the Continuous Delivery pipeline that update the 
slides on the web.

See
* [continuous-delivery-slides-example wiki](docs/Home.md) (includes slides)
* [reveal.js readme](README-reveal-js.md)

# Build

See [`Jenkinsfile`](Jenkinsfile).

* Deploys all branches to nexus repo defined in [`pom.xml`](pom.xml)
* Requires username and password credentials `jenkins` defined in Jenkins.
* Deploys master branch also to Kubernetes instance defined in [`Jenkinsfile`](Jenkinsfile)
  * Docker Registry: Requires username and password credentials `gcloud-docker` defined in Jenkins.
  * Kubernetes: Requires Kubeconfig file defined as Jenkins file credential `kubeconfig-bc-production`.
* Needs Docker available on the jenkins worker
* On failure, sends emails to git commiter, on master and develop also to global env var `EMAIL_RECIPIENTS` (if configured in Jenkins)
