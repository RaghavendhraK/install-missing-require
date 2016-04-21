# install-missing-require

This project just installs the modules(with the latest version) __that are not present in package.json but used in the code using require statement__.

####What it does####
* Installs the node modules with the _same_ version, present in the package.json.
* Installs the node modules with the _latest_ version, not present in package.json but used in code.
* Updates the newly installed modules in the package.json(basically npm does it).
* Neglect the modules like fs, path,... which belongs to the nodejs
* Neglect the local required modules

####Usability is simple####
* Download or clone this project.
* cd to this project.
* Run "npm install".
* Run "coffee index.coffee /path/to/src/dir/of/your/code".

####Sample####
For sample run "coffee index.coffee /test/data"
