*** UNDER CONSTRUCTION ***

So, you are already familiarized with Lua and you think the best way to get the new feature you want fast is to program it yourself ? Or you feel like reporting bugs isn't enough, you want to fix them yourself ? Either way, you need some more information to contribute to Moose.

This guide assumes that you are already familiar with Moose and that you already set up your development environment. If it is not the case, please go through the [Tester Guide](Beta_Test_Guide.html) before proceeding.

In this document, we will review

1. GitHub/Git organisation
2. Contribution guidelines
3. Coding standards
4. The Luadoc
5. Moose release cycle
6. The Issue Tracker : labels and milestones

# 1) GitHub/Git organisation

## 1.1) The Repositories

## 1.2) Branches

## 1.3) Commits

## 1.4) Merge/Pull Requests

# 2) Contribution guidelines

We try to follow a contribution process, to make sure we work efficiently together. It isn't set in stone, but it gives an idea of what should be done. We wouldn't want two contributors both working on the same issue at the same time, would we ? This applies more to new features, the process for bug fixes is more flexible and several steps can be overlooked.

1. Think about what you are trying to achieve. Writing some pseudocode is a great way to undersatnd the challenges you are going to face.
2. Discuss your idea with the community on Slack. Maybe there is a way to do it you didn't even think about, or maybe you could team up with someone who is already working on it!
3. Create a high level design document. It doesn't need to be thorough, but you need to have an idea of which class do you want to write, which class they should inherit from, which methods are needed in each class...
4. Write an issue on GitHub with your high level design document, apply the label "enhancement", and assign it to yourself.
5. Create a new branch to work on.
6. Write your code in your branch following the Coding Standards, sync fairly regularly this branch with master, so that you don't have tons of merge conflicts at the end.
7. When done, write a/some test mission(s) to showcase how to use your feature to the community.
8. Generate the Luadoc
9. Relsove merge conflicts with master and create a new pull request.
10. Delete your branch if you are not going to use it again.

# 3) Coding Standards

To ensure a good degree of consistency in Moose's code, we follow the following standards :

* The code need to be intellisense/Luadoc compatible. See below for more information
* The code needs to be commented. Remember : _“Programs must be written for people to read, and only incidentally for machines to execute.”_ - Hal Abelson
* Indentation must be 2 spaces (default in LDT)
* Class names must be in capital letters (e.g. SPAWN)
* Class should all inherit from BASE
* Methods should start by a capital letter (e.g. GetName())
* If your method is intended for private use only, its name should start with an underscore (e.g. _GetLastIndex())
* Variables should start with a capital leter (e.g. IndexString)
* Provide a trace for the mission designer at the start of every method, and when it is appropriate. Trace functions are inherited from BASE :
  * F(), F2() and F3() for function calls,
  * T(), T2() and T3() for function logic, 
  * And E() for errors. 

# 4) The Luadoc

The Luadoc system is not only useful for the contributor to understand the code, but also the mission designer, as it used to automatically generate the [HTML documentation](http://flightcontrol-master.github.io/MOOSE/Documentation/index.html).
It thus needs to follow some strict standards.
Keep in mind the following informations :

* Every Luadoc block needs to start with three minus signs (`---`).
* The generated html file will use Markdown. If you are not familar with it, use this [reference](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
* You can create hyperlinks by writing
  * @{Module#CLASS.Method} for a method
  * @{Module#CLASS} for a class
  * Module can be ommited if the hyperlink points to the same module (e.g. @{#CLASS} is valid if CLASS is in the Module the link is in)
* Luadoc types the variables. the following types are available
  * Folder.Module#CLASS (a Moose class)
  * Dcs.DCSTypes#Class (a DCS class)
  * \#string
  * \#number (integer or floating point)
  * \#boolean
  * \#nil

## 4.1) Modules

Every new file should contain at least one module, which is documented by a comment block. You can copy paste the following model and fill in the blanks :

```lua
--- **Name of the Module** - Short Description
-- 
-- ===
-- 
-- Long description. Explain the use cases.
-- Remember that this section will be red by non programmers !
-- 
-- ===
--
-- ### Authors : Your name/pseudnyme
--
-- @module Module
```

## 4.2) Classes

Every class should be documented by a comment block. You can copy paste the following model and fill in the blanks :

```lua
--- **Name of the CLASS** class, extends @{Module#CLASS}
-- 
-- Long description. Explain the use cases.
-- Remember that this section will be red by non programmers !
--
-- @type CLASSNAME
-- @field #type AttributeName (add a @field for each attribute)
-- @extends Folder.Module#CLASS
```

## 4.3) Methods

Every method should be documented by a comment block. You can copy paste the following model and fill in the blanks :

```lua
--- Description of the method
-- @param #type (add a @param for each parameters, self included, even if it's implied)
-- @return #type (add other @return fields if the method can return different variables)
-- @usage (can be omitted if the usage is obvious)
-- -- Explain how to use this method
-- -- on multiple lines if you need it !
```language
```

# 5) Moose release cycle
To ensure that the next Release of Moose is as bug-free and feature rich as possible, every Moose contributor respects a release cycle. 
![](Installation/MOOSE_Release_Cycle.JPG)

The key takeways are:

* During "normal" time, write your features and correct bugs as you please
* During "Feature Freeze", you can still work on your features, but you are strongly encouraged to prioritize bug fixes, especially if it involves your code. No pull request for new features will be accepted during feature freeze !
* After the Release, it's back to the start for a new cycle.

# 6) The Issue Tracker : labels and milestones

## 6.1) Milestones

## 6.2) Label