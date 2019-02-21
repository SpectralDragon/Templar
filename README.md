# Templar - a new way for template generating

### How it work?

For begining you are should install Templar in your project.

```bash
templar init
```
Templar create YAML config `.templar` and `.templates` directory.

##### 1) `.templar`

`.templar` contains information about your project and path for templates directory. 

Example:

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

After install your templar, you are can use command `templar template new [templateName]` for generation a template directory with blank. 
**Each template going to contains in personal folder.**

The template directory contains `[templateName].templar` and looks like this:

```yaml
version: 1.0.0 # template version. 
summary: ENTER_YOUR_SUMMORY # Bit of information about your template and what it do.
author: ENTER_YOUR # Authour name or links
root: Sources/templar # Path to folder where templar will generate your templates.
files: # Tempalte files
  - path: View/ViewController.swift # Path for place where file will contains after process
    templatePath: View/ViewController.swift.templar # Path to template
replaceRules: # Keys for replacing
   - pattern: __NAME__ # Key for replace. You can use regexp here.
     question: 'Name of your module:' # Question will display in terminal and answer will use for replace pattern
```

### How to write template?

The first you going to set pattern for replace. Like example it will `__NAME__`

```swift
class __NAME__ViewController: UIViewController {
  // Other code
}
```

After generating your pattern will replacing on user answer.

Next chapter: 

Pattern can be modified with next separated keys:

* lowercase
* firstLowercased
* uppercase
* firstUppercased
* snake_case

**Notifce: All modifier can be use for each pattern once. Also modifier case sensative!**

Example with modifiers:

```swift
class __NAME__Presenter {

func __NAME__=firstLowercased=ViewControllerDidLoad() {
     // Code
}

}
```

### Scripts?

Yup, Templar is supported scripts. Scripts will run after template generation and will execute in bash.

For creating scripts just use command: `templar template new [templateName] --use-scripts` or set manual `scripts:` parameter to your template.

Like example generate the new xcodeproj for your SPM project:

```yaml
...
scripts:
  - swift package generate-xcodeproj
```

### Installation

 Homebrew

```bash
brew cask install templar
```

## Author

Vladislav Prusakov, [twitter](twitter.com/mashiply)

## License

Templar is available under the MIT license. See the LICENSE file for more info.
