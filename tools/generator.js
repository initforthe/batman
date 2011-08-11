(function() {
  var Batman, cli, fs, path, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require('fs');
  path = require('path');
  util = require('util');
  cli = require('./cli');
  Batman = require('../lib/batman.js');
  cli.setUsage('batman [OPTIONS] generate app|model|controller|view <name>\n  batman [OPTIONS] new <app_name>');
  cli.parse({
    app: ['-n', "The name of your Batman application (if generating an application component). This can also be stored in a .batman file in the project root.", "string"]
  });
  cli.main(function(args, options) {
    var command, count, destinationPath, replaceVars, source, transforms, varMap, walk;
    options.appName = options.app;
    command = args.shift();
    if (command === 'new') {
      options.template = 'app';
      if (args[0] == null) {
        this.error("Please provide a name for the application.");
        cli.getUsage();
      }
      options.name = args[0];
    } else if (args.length === 2) {
      options.template = args[0];
      options.name = args[1];
    } else {
      this.error("Please specify a template and a name for batman generate.");
      cli.getUsage();
    }
    source = path.join(__dirname, 'templates', options.template);
    if (!path.existsSync(source)) {
      this.fatal("template " + options.template + " not found");
    }
    if (options.template === 'app') {
      if (options.appName != null) {
        options.name = options.appName;
      } else {
        options.appName = options.name;
      }
      destinationPath = path.join(process.cwd(), options.appName);
      if (path.existsSync(destinationPath)) {
        this.fatal('Destination already exists!');
      }
      fs.mkdirSync(destinationPath, 0755);
      fs.writeFileSync(path.join(destinationPath, '.batman'), options.appName);
    } else {
      destinationPath = process.cwd();
      if (options.appName == null) {
        try {
          options.appName = fs.readFileSync(path.join(process.cwd(), '.batman')).toString().trim();
        } catch (e) {
          if (e.code === 'EBADF') {
            this.fatal('Couldn\'t find out the name your project! Either pass it with --app or put it in a .batman file in your project root.');
          } else {
            throw e;
          }
        }
      }
    }
    options.appName = Batman.helpers.camelize(options.appName);
    varMap = {
      app: options.appName,
      name: options.name
    };
    transforms = [
      (function(x) {
        return x.toUpperCase();
      }), (function(x) {
        return Batman.helpers.camelize(x);
      }), (function(x) {
        return x.toLowerCase();
      })
    ];
    replaceVars = function(string) {
      var f, templateKey, value, _i, _len;
      for (templateKey in varMap) {
        value = varMap[templateKey];
        if (value == null) {
          console.error("template key " + templateKey + " not defined!");
        }
        for (_i = 0, _len = transforms.length; _i < _len; _i++) {
          f = transforms[_i];
          string = string.replace(new RegExp("\\$" + (f(templateKey)) + "\\$", 'g'), f(value));
        }
      }
      return string;
    };
    count = 0;
    walk = __bind(function(aPath) {
      var sourcePath;
      if (aPath == null) {
        aPath = "/";
      }
      sourcePath = path.join(source, aPath);
      return fs.readdirSync(sourcePath).forEach(__bind(function(file) {
        var destFile, dir, ext, newFile, oldFile, resultName, sourceFile, stat;
        if (file === '.gitignore') {
          return;
        }
        resultName = replaceVars(file);
        sourceFile = path.join(sourcePath, file);
        destFile = path.join(destinationPath, aPath, resultName);
        ext = path.extname(file).toLowerCase().slice(1);
        stat = fs.statSync(sourceFile);
        if (stat.isDirectory()) {
          dir = path.join(destinationPath, aPath, resultName);
          if (!path.existsSync(dir)) {
            fs.mkdirSync(dir, 0755);
          }
          return walk(path.join(aPath, file));
        } else if (ext === 'png' || ext === 'jpg' || ext === 'gif') {
          newFile = fs.createWriteStream(destFile);
          oldFile = fs.createReadStream(sourceFile);
          this.info("creaitng " + destFile);
          return util.pump(oldFile, newFile, function(err) {
            if (err != null) {
              throw err;
            }
          });
        } else {
          if (file.charAt(0) === '.') {
            return;
          }
          count++;
          return fs.readFile(sourceFile, 'utf8', __bind(function(err, fileContents) {
            if (err != null) {
              throw err;
            }
            this.info("creating " + destFile);
            return fs.writeFile(destFile, replaceVars(fileContents), __bind(function(err) {
              if (err != null) {
                throw err;
              }
              if (--count === 0) {
                return this.ok("" + options.name + " generated successfully.");
              }
            }, this));
          }, this));
        }
      }, this));
    }, this);
    return walk();
  });
}).call(this);
