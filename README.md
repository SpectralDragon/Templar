# Templar - a new way for template generating

### How it work?

For beginning you are must install Templar in your project.

```bash
templar init
```

or if your project using xcode:

```bash
templar init --xcodeproj
```

Templar will create YAML config `.templar` and `.templates` directory.

Let's talk about each a new generated file:

##### 1) `.templar`

`.templar` contains information about your project and path for templates directory. 

For example we will talk about project using xcode:

```yaml
kind: # Information about your project
  xcodeproj:
    name: templar.xcodeproj # your project file name
    targets: # list of targets for generation
      - templar
     templates: # list of templates name
      - mvvm
version: 1.0.0 # config version 
templateFolder: .templates # path to templates directory
```

##### 2) Templates

After install your templar, you can use command `templar template new [templateName]` for generation a template directory with blank. 
**Each template going to contains in personal folder.**

The template directory will contains `[templateName].templar` and looks like this:

```yaml
version: 1.0.0 # template version. 
summary: ENTER_YOUR_SUMMORY # Bit of information about your template and what it do.
author: ENTER_YOUR # Authour name or links
root: Sources/templar # Path to folder where templar will generate your templates.
files: # Tempalte files
  - path: View/ViewController.swift # Path for place where file will contains after process
    templatePath: View/ViewController.swift.templar # Path to template
replaceRules: # Keys for replacing
   - pattern: __CLASS_NAME__ # Key for replace. You can use regexp here.
     question: 'Name of your class:' # Question will display in terminal and answer will use for replace pattern
```

### How to use?

```bash
templar generate [templateName] [moduleName]
```

Templar will asks the user questions from your template config file and will replace each pattern on answer. Pretty simple, right?

### How to write template?

The first you going to create template file and set patterns for replace. Like example it will `__CLASS_NAME__`

```swift
class __CLASS_NAME__ViewController: UIViewController {
  // Other code
}
```

After that you should add path to your template file and path to finish directory in your template config.

```yaml
varsion: 1.0.0
files:
 - path: View/ViewController.swift
   templatePath: View/ViewController.swift.templar
```

Okay, that it. When you will generate template, Templar will create the file using `[moduleName]` like name of your files. Like example `View/MyPrettyViewController.swift`.

Templar will replacing each pattern using user answer from question.

Next chapter: 

Pattern can be modified with next separated keys:

* =lowercase=
* =firstLowercased=
* =uppercase=
* =firstUppercased=
* =snake_case=

**Notifce: All modifier can be use for each pattern once. Also modifier case sensative!**

Example with modifiers:

```swift
class __CLASS_NAME__Presenter {

func __CLASS_NAME__=firstLowercased=ViewControllerDidLoad() {
     // Code
}

}
```

### Default patterns

Templar there is default patterns for replacing. 

* `__NAME__` - module name taken from argument [moduleName]
* `__FILE__` - file name
* `__PROJECT__` - project name taken from templar `config -> xcodeproj -> name` or nil. Can be modified with template settings `template -> settings -> projectName`
* `__AUTHOR__` - author name, taken from `template -> author`. If author name not exists in template, this key will not replace.
* `__YEAR__` - current year.
* `__DATE__` - current date with format dd/MM/YYYY. Can be modified with template settings `template -> settings -> dateFormat`
* `__COMPANY_NAME__` - your company name taken from `templar -> companyName` or nil.
* **(FUTURE)** `__LICENSE__` - will replace key on license file in project root directory. Path can be modified with template settings `template -> settings -> licensePath`. OR take license template and replace each key using default patterns. 

### Template settings

Settings will contains specification for replacing or some action will add in future.

```yaml
version: 1.0.0
settings:
  dateFormat: dd/MM/YY
  projectName: Templar
  licensePath: LICENSE #will add in future release
```

### Scripts?

Yup, Templar supported scripts. Scripts will run when template did finish successfully and will execute using bash.

For creating scripts just use command: `templar template new [templateName] --use-scripts` or set manual `scripts:` parameter to your template.

Like example generate a new xcodeproj for your SPM project:

```yaml
...
scripts:
  - swift package generate-xcodeproj
```

### Installing

Using Makefile 

```bash
$ git clone https://github.com/SpectralDragon/Templar.git
$ cd Templar
$ make
```

Using [Mint 🌱](https://github.com/yonaskolb/mint)

```bash
mint install SpectralDragon/Templar
```

Using the [Swift Package Manager 🛠](https://github.com/apple/swift-package-manager) 

```bash
$ git clone https://github.com/SpectralDragon/Templar.git
$ cd Templar
$ swift build -c release -Xswiftc -static-stdlib
$ cd .build/release
$ cp -f templar /usr/local/bin/templar
```

## Author

Vladislav Prusakov, [twitter](twitter.com/mashiply)

## License

Templar is available under the MIT license. See the LICENSE file for more info.
