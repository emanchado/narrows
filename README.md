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
1. Make sure you have Node.js (at least version 10) and NPM (at least
   version 4).
1. Run `npm install`
1. [Install Elm 0.19.1](https://guide.elm-lang.org/install/elm.html)
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

## Running the tests

To be able to run the tests you need to create two test databases: the
main one, and the "user storage" one. For the first one you have the
settings in `config/test.js`. The second one is the same, except for
the database name, which is `narrows-userstore-test`.

Once you have the two databases created and the test user created and
have given access to them, you can run the tests by typing:

    npm t


# Docker

This repo includes a Dockerfile for building a deployable image. It
also contains a `docker-compose.yaml` suitable for quickly getting a
local copy running.  The Dockerfile and compose file have been used
(with modification) to host a production version of the app.

To get going with docker-compose:

`docker-compose create && docker-compose up -d`

If you want to host it publicly and setup e-mail, add the appropriate
Docker environment variables from below:

* `PORT`: port to listen to.
* `PUBLIC_ADDRESS`: used to generate URLs in e-mails.
* `DB_HOST`: MySQL hostname/IP.
* `DB_USER`: MySQL username.
* `DB_PASSWORD`: MySQL password.
* `DB_NAME`: database name.
* `FROM_EMAIL`: e-mail address to send from. e.g. `"Narrows" <no-reply@domain.com>`.
* `NODEMAILER`: a nodemailer URI configuration string, e.g. `smtps://user:pasword@smtp.host.com/?secure=true`.

__Note:__ `NODEMAILER` URI strings need to URI escape special
characters within username/password. For example, usernames often
contain `@`, and AWS SES passwords often contain `/`.

# Credits

## Icons/graphics

* Speaker/mute icons made by
  [Madebyoliver](http://www.flaticon.com/authors/madebyoliver), from
  [Flaticon](http://www.flaticon.com). They are licensed under
  Creative Commons BY 3.0.
* Trash icon by [Freepik](http://www.flaticon.com/authors/freepik),
  from [Flaticon](http://www.flaticon.com). Licensed under Creative
  Commons BY 3.0.
* Add/plus icon, message icon, user icon, info icon and edit icon by
  [Lucy G](http://www.flaticon.com/authors/lucy-g), from
  [Flaticon](http://www.flaticon.com). Licensed under Creative Commons
  BY 3.0.
* RSS icon by [Dave Gandy](http://www.flaticon.com/authors/dave-gandy)
  from [Flaticon](http://www.flaticon.com). Licensed under Creative
  Commons BY 3.0.
* Vintage divider by
  [Web Design Hot](http://www.webdesignhot.com/free-vector-%20graphics/vector-set-of-vintage-design-divider-elements/). Licensed
  under Creative Commons BY 3.0.

## Contributors

* Tess Gadwa ([`tessgadwa`](https://github.com/tessgadwa)): UX help and recommendations.
* James Sapara ([`interlock`](https://github.com/interlock)): Docker setup.
