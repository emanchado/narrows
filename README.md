# NARROWS

NARROWS is an online storytelling system. The name stands for
NARRation On Web System. The easiest way to explain it is to
imagine an online
[Choose Your Own Adventure](https://en.wikipedia.org/wiki/Choose_Your_Own_Adventure)
book with the following differences:

1. Instead of having a single reader, there are as many readers as
   protagonists in the story (it could be one, but also four or five).
1. Instead of having to choose between two or three preset choices
   after each "chapter", readers can _write_ in a textbox whatever
   their characters do.
1. Instead of the narrator writing the whole story with all possible
   branches upfront, then give it to the readers; the narrator writes
   only one chapter at a time and waits for the readers to submit the
   "actions" for their characters. Based on those actions, the
   narrator writes the next chapter.

You can also think of it as a way of running ruleless, diceless RPGs
online (which is indeed the reason why I wrote it in the first
place).


# Installation

NARROWS is a web application with a backend. As such, it needs a
server connected to the internet to be used. To install you need to
run the following steps:

1. Clone the code somewhere.
1. Make sure you have Node.js (at least version 4) and NPM (at least
   version 4).
1. Run `npm install`
1. Run `npm install -g elm@0.18`
1. Run `elm-package install`
1. Run `npm run build`
1. Install MySQL, create a new user and an empty MySQL database. Make
   sure the new user has all privileges to that database.
1. Copy `config/default.js` to `config/local-production.js` and modify
   any values you need.
1. Run `NODE_ENV=production npm run dbmigrate`
1. Run `NODE_ENV=production node build/index.js`

If all this works you will have to find a way to keep the server
running, eg. [supervisor](http://supervisord.org/).

## Updating the code

Every time you update the code you will have to install any new
dependencies with:

    npm install

And run any new migrations with the following command. Note that you
might need to pass the `NODE_ENV` variable as in the installation
instructions above:

    npm run dbmigrate

Then you will have to recompile the frontend and backend code with:

    npm run build

# Docker

This repo includes a Dockerfile for building a depoyable image. It also
contains a docker-compose suitable for quickly getting a local copy running.
The Dockerfile and compose file have been used (with modification) to host
a production version of the app.

To get going with docker-compose:

`docker-compose create && docker-compose up -d`

If you want to setup email and use as a publicly hosted site, add the
appropriate environment variables from below.

Docker environment variables:
- PORT - port to listen to
- PUBLIC_ADDRESS - used to generate urls in emails
- DB_HOST - hostname/ip
- DB_USER - mysql username
- DB_PASSWORD - mysql password
- DB_NAME - database name
- FROM_EMAIL - email address to send from. e.g. "Narrows" <no-reply@domain.com>
- NODEMAILER - a nodemailer URI configuration string. e.g. smtps://user:pasword@smtp.host.com/?secure=true

__Note__ NODEMAILER URI strings need to URI escape special characters within
username/password. SES loves to give passwords that contain "/" for example.

# Credits

* Speaker/mute icons made by
  [Madebyoliver](http://www.flaticon.com/authors/madebyoliver), from
  [Flaticon](http://www.flaticon.com). They are licensed under
  Creative Commons BY 3.0.
* Trash icon by [Freepik](http://www.flaticon.com/authors/freepik),
  from [Flaticon](http://www.flaticon.com). Licensed under Creative
  Commons BY 3.0.
* Add/plus icon, message icon, user icon and info icon by
  [Lucy G](http://www.flaticon.com/authors/lucy-g), from
  [Flaticon](http://www.flaticon.com). Licensed under Creative Commons
  BY 3.0.
* RSS icon by [Dave Gandy](http://www.flaticon.com/authors/dave-gandy)
  from [Flaticon](http://www.flaticon.com). Licensed under Creative
  Commons BY 3.0.
* Vintage divider by
  [Web Design Hot](http://www.webdesignhot.com/free-vector-%20graphics/vector-set-of-vintage-design-divider-elements/). Licensed
  under Creative Commons BY 3.0.
