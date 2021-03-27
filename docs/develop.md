# Developer notes

## Development setup

To develop, open a terminal with `npm run startdev`, another one with
`npm run watchfe`, and a third one with `npm run watchbe`. The
application should be running on port 3000.

## Creating new pages

If you know Elm, it should be reasonably easy to get into this
code. Creating new pages, however, is particularly involved.

1. In `Main.elm`, add a new import line for the new page app.
1. In `Main.elm`, add a new key to `initialState` at the top.
1. In `Main.elm`, update `dispatchEnterLocation` with a new variable,
   a new model update, and a new command in the `Cmd.batch` call.
1. In `Main.elm`, update `combinedUpdate` to add a message handling
   case for the new app. *Make sure* that the command returned by the
   new branch has (or doesn't have) a call to `protectedCmd` depending
   on whether the page is supposed to be accessible by anonymous users
   or not.
1. In `Main.elm`, update `subscriptions` to add a `Sub.map` for the
   new app's messages.
1. Create a file called `NewApp.elm` and a directory called
   `NewApp`. Copy their contents from `UserManagementApp.elm` and
   `UserManagementApp/` respectively, and adapt names.
1. In `app/Core/Routes.elm`, add a new route for the page.
1. In `app/Core/Messages.elm`, add a new pattern for the new app's
   messages.
1. In `app/Core/Models.elm`, add a new field for the new app.
1. In `app/Routing.elm`, register the URL associated with the page.
1. In `app/Core/Views.elm`, add handling for the page (in
   `appContentView` if it doesn't require login, or in
   `dispatchProtectedPage` otherwise).
