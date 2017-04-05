# MicroAuthority

If you've got a list of people and you'd like to publish them on the web as Linked Open Data, MicroAuthority is a simple, bare-bones system that provides an API, search, and other tools for developers and digital researchers.

MicroAuthority creates both HTML & Linked Open Data endpoints for institutional Agent authority files—lists of people, organizations, and groups. Data is provided by the institution as a CSV file. MicroAuthority automatically creates a unique URI for every row in that CSV file that works as both a webpage and as machine-readable Linked Open Data.

This has only been tested on datasets in the ~20,000 row size as of yet—it should scale to ~100,000 (or perhaps more), but nobody's tried yet.  Beta software, etc, etc.

## Getting Started

### TL;DR Instructions.

*(These instructions are for people famillar with the process of installing Ruby software from Github.  If this doesn't make sense, move on to the next section.)* 

1. [Fork](https://github.com/arttracks/microauthority) and clone the repository. 
2. Modify the `data/data.csv` file to reflect your data.  Don't worry about missing data for columns—you don't have to fill them all in.  The only required fields are `id` and `name`.  Order doesn't matter.  
3. Edit the `config/settings.yaml` file to add institution specific information.
4. Within the repo directory, install local dependencies: `gem install foreman bundler && bundle install`
5. Initialize the sitemap: `rake sitemap:create`

To run the application locally: `foreman start` will start the server running.  Typing `CONTROL-C` into the terminal will quit the server.

The site will now be running at <http://localhost:5000>. T

### Full Installation Instructions.

In order to setup MicroAuthority for your data, it's often helpful to run a copy of it on your own computer.  This way, you can try it out and see what it's doing before you run it out on the internet somewhere.   These instructions are designed to work on a Mac, but they would be similar or identical for any UNIX-based system.  If you're interested in running this on a Windows system, get in touch—I would be helpful to work with you to figure out how to install it and to write documentation for Windows.


#### Downloading the Software

Before you can run the software, you need to download a copy of the code onto your computer.  This code is available on [Github](https://github.com), which is a website where people often put code that they would like other people to have access to.  (You've obviously found it, since you're reading this here!) 

There are two ways to download this—the *easy* way and the *complicated* way.  The benefit of the easy way is that it's easy.  The benefit of the complicated way is that it makes it easy to contribute changes you make to the software back to the project.  If you think it's unlikely that you're going to be fixing bugs in MicroAuthority, and you just want to get it up and running, choose the easy way.

The **easy** way to get a copy is to [download the software as a ZIP file](https://github.com/arttracks/microauthority/archive/master.zip) directly from Github.  This will download a directory containing *most* of the software that you need to run MicroAuthority.  To get the rest, you'll need to install MicroAuthority's *dependencies*, which are the parts of MicroAuthority that were not written for this project, but are used within the software.  An poor analogy would be to think of them as the software that MicroAuthority *references*.  The **Dependencies** section of these instructions will describe how to do that.  You can now skip the rest of this section and go to **Navigating to the Directory**.

The **hard** way to **clone** the Github repository.  This uses a tool called `git`, which is a tool for version control of software.  Version control is similar to version tracking for Word documents—it keeps the history of how the software changes, who changed it, and when.  It also allows you to "fork" or "branch" the code, so you can try out changes without losing the ability to go back to how the software was before you started changing things. For a full explanation, see the [Getting Started: Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics) chapter of the [Pro Git](https://git-scm.com/book/en/v2) book, which discussed many of the concepts at length.

If you'd rather just get started using Git, Github provides (a helpful set of instructions for installing git)[https://help.github.com/articles/set-up-git/]. If your computer doesn't already have a copy of it, you'll need to install a version of `git` on your computer. It doesn't matter if you use the Desktop version or the Command Line version—both do the same thing.

One you have git installed and configured, you will to clone [this repository](https://github.com/arttracks/microauthority).  This will download a copy of the software that also contains special files (in a `.git` directory) that contain a full copy of the history of the code, as well as metadata that describes where the software came from, how to download it again, and how to submit any changes you make to the software back to the project. 

If you're using the command line you can do this by typing:

`git clone git@github.com:arttracks/microauthority.git`

which will create a directory called `microauthority` that contains the software.  

#### Navigating to the Directory in the Terminal

Now that you have a copy of the code, you should put that directory somewhere you'll remember it.  If you downloaded it directly, you should also rename the directory to `microauthority`.  This isn't required for it to work, but the rest of the instructions assume that it's called that, and you'll be confused if you don't.

We're going to be using the Terminal, also known as "the command line".  This is a special piece of software that comes with you computer that lets you run programs and look at files using a text-based interface.  You type commands, and it does things.  This is the way that all computers used to work, back before things like Windows or MacOS came along—and it's often much more *efficient* than clicking on icons.  Programmers love efficiency, so most of the tools that we use run from the command line. For a basic tutorial on the command line and Terminal, see [David Baumgold's tutorial](https://www.davidbaumgold.com/tutorials/command-line/) (which is friendlier) or [Apple's tutorial](https://developer.apple.com/library/content/documentation/OpenSource/Conceptual/ShellScripting/CommandLInePrimer/CommandLine.html) (which is more complete).

You'll need to open up **Terminal** on your computer, and then you're going to change Terminal's "working directory" to `microauthority`.  This is the same as opening the folder in Finder—it tells the computer that any files it needs and any commands you run should be done in the context of that folder. To do this, we need to use the command `cd`, or **c**hange **d**irectory.  

The command

```
cd microauthority
```

will change the working directory to `microauthority`.  However, this will only work if you're in the directory one level up from it—you'll need to type the whole file path to that directory.  If you don't know it, an easy trick is to type `cd ` (note the space after the d) and then *drag* the folder from the Finder into the Terminal.  Dragging a folder into terminal will *type* the full path of that directory for you.

You should do this, because the rest of the commands that we'll be typing will assume that you're inside the `microauthority` directory.

#### Installing Dependencies

*(WIP— continue writing from here, David.)*

One you have a copy of it locally, you should modify the `data/data.csv` file to reflect your own data.  Don't worry about missing data for columns—you don't have to fill them all in.  


To test it locally, you need to do the following:

```
bundle install
rake sitemap:create
foreman start
```

There is no database used for this project and no additional software needed.  I recommend deploying it to something like Heroku—there's not a lot of dependencies involved.



## Credit and the Like

Feel free to take this, fork it, and use it as you like.  We'd really appreciate a link or a thanks as part of your deployment, but there's no requirement to do so.

Go ye, and make the web more link-tastic!

**MicroAuthority** is a project of the <a href='http://www.museumprovenance.org'>Art Tracks</a> program at <a href='http://www.cmoa.org'>Carnegie Museum of Art</a>.Funding has been provided by the <a href='http://www.neh.gov/'>National Endowment for the Humanities</a>.