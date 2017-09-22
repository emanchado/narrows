const {emDash, ellipsis, smartQuotes, inputRules} = require("prosemirror-inputrules")
const {keymap} = require("prosemirror-keymap")
const {history} = require("prosemirror-history")
const {baseKeymap} = require("prosemirror-commands")
const {Plugin} = require("prosemirror-state")
const {menuBar} = require("prosemirror-menu");

const {buildMenuItems} = require("./menu")
exports.buildMenuItems = buildMenuItems
const {buildKeymap} = require("./keymap")
exports.buildKeymap = buildKeymap


const allInputRules = smartQuotes.concat([emDash, ellipsis]);

// !! This module exports helper functions for deriving a set of basic
// menu items, input rules, or key bindings from a schema. These
// values need to know about the schema for two reasons—they need
// access to specific instances of node and mark types, and they need
// to know which of the node and mark types that they know about are
// actually present in the schema.
//
// The `editorSetup` plugin ties these together into a plugin that
// will automatically enable this basic functionality in an editor.

// :: (Object) → [Plugin]
// A convenience plugin that bundles together a simple menu with basic
// key bindings, input rules, and styling for the example schema.
// Probably only useful for quickly setting up a passable
// editor—you'll need more control over your settings in most
// real-world situations.
//
//   options::- The following options are recognized:
//
//     schema:: Schema
//     The schema to generate key bindings and menu items for.
//
//     mapKeys:: ?Object
//     Can be used to [adjust](#example-setup.buildKeymap) the key bindings created.
function editorSetup(options) {
  let deps = [
    inputRules({rules: allInputRules}),
    keymap(buildKeymap(options.schema, options.mapKeys)),
    keymap(baseKeymap)
  ]
  if (options.history !== false) deps.push(history())

  return deps.concat(menuBar({
    floating: true,
    content: buildMenuItems(options.schema).fullMenu
  }))
}
exports.editorSetup = editorSetup
