# Operate templates for projects

## Usage


```
Operate directory templates
commands:
    ls                                       List available templates
    content  <template_name>                 Print content of template
    rm       [template_name...]              Remove template
    export   <template_name>                 Export content of template to current dir
    init     <template_name...>              Initialize directory and apply templates
    save     [template_name]                 Save current directory as template
    backup   <archive name>                  Compress all templates to tar.gz
    restore  <archive name>                  Unpack all templates from tar.gz
    pull                                     Pull templates from remote repo
    push                                     Push templates to remote repo
    help                                     Show help
    install                                  Install script to /usr/bin/mkproj
```


## How to create template


1. Create a directory `mkdir template_name`
2. Put some files
3. Save template by `mkproj save`


## Special files


`post-init` - executable script (+x) that runs after apply template

`TARGET_FILE.template` - template that will processed by `envsubst`

`TARGET_FILE.cgi`  - script, that output will save instead of it (aka CGI in web)


## How to use template

1. Run `mkproj ls` and remember template name
2. Run `mkproj init TEMPLATE_NAME` and be happy
