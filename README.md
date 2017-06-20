# Aether VoID statistics tool

[![DOI](https://zenodo.org/badge/5847/jiemakel/aether.png)](http://dx.doi.org/10.5281/zenodo.11755)

see http://jiemakel.github.io/aether/ , http://www.seco.tkk.fi/publications/2014/makela-aether-2014.pdf

Cite:

    @inproceedings{makela-aether-2014,
      author =   {Eetu Mäkelä},
      title =    {Aether -- Generating and Viewing Extended VoID Statistical Descriptions of RDF Datasets},
      year = {2014},
      booktitle = {Proceedings of the ESWC 2014 demo track, Springer-Verlag},
    }

## Building

### Prequisites

 1. Make sure you have [Node.js](https://nodejs.org/en/) installed (for example using [nvm](https://github.com/creationix/nvm)).
 1. Make sure you have [Bower](http://bower.io/) installed (`npm install -g bower`)
 1. Make sure you have [Gulp](http://gulpjs.com/) installed (`npm install -g gulp`)

### Setting up the build environment

Run `npm install` and `bower install`.

### Building

To simply build the project, run `gulp`. However, when actually working, you probably want to use `gulp serve`, which spawns the app in a browser, and stays to watch for changes in the project files, automatically recompiling them and reloading them into the browser.

To build a distribution version of the project (with e.g. combined and minified js and css files), use `gulp dist`. This will create the directory `dist`, which you can then copy to your production server.
