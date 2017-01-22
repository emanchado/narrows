const {wrapItem, blockTypeItem, Dropdown, DropdownSubmenu, joinUpItem, liftItem,
       selectParentNodeItem, undoItem, redoItem, icons, MenuItem} = require("prosemirror-menu")
const {toggleMark} = require("prosemirror-commands")
const {wrapInList} = require("prosemirror-schema-list")
const {TextField, SelectField, openPrompt} = require("./prompt")
const {FileUploaderField, MultiSelectField} = require("./prompt-extra")

// Helpers to create specific types of items

function canInsert(state, nodeType, attrs) {
  let $from = state.selection.$from
  for (let d = $from.depth; d >= 0; d--) {
    let index = $from.index(d)
    if ($from.node(d).canReplaceWith(index, index, nodeType, attrs)) return true
  }
  return false
}

function insertImageItem(nodeType) {
    return new MenuItem({
        title: "Insert image",
        label: "Image",
        select(state) { return canInsert(state, nodeType) },
        run(state, _, view) {
            let {node} = state.selection, attrs = nodeType && node &&
                    node.type == nodeType && node.attrs;
            const uploadUrl = `/api/narrations/${view.props.narrationId}/images`;

            openPrompt({
                title: "Choose an image",
                fields: {
                    src: new SelectField({label: "Image",
                                          required: false,
                                          selected: attrs && attrs.src,
                                          options: view.props.images.map(img => ({value: img, label: img}))}),
                    uploader: new FileUploaderField({required: false,
                                                     addImageCallback: name => {
                                                         view.props.images.push(name);
                                                     },
                                                     url: uploadUrl})
                },
                // FIXME this (and similar uses) won't have the current state
                // when it runs, leading to problems in, for example, a
                // collaborative setup
                callback(attrs) {
                    const imageName = attrs.uploader || attrs.src;
                    if (!imageName) {
                        return;
                    }
                    const imageUrl = `/static/narrations/${view.props.narrationId}/images/${imageName}`;
                    view.dispatch(view.state.tr.replaceSelectionWith(nodeType.createAndFill({src: imageUrl})));
                    view.focus();
                }
            });
        }
    });
}

function positiveInteger(value) {
  if (!/^[1-9]\d*$/.test(value)) return "Should be a positive integer"
}

function cmdItem(cmd, options) {
  let passedOptions = {
    label: options.title,
    run: cmd,
    select(state) { return cmd(state) }
  }
  for (let prop in options) passedOptions[prop] = options[prop]
  return new MenuItem(passedOptions)
}

function markActive(state, type) {
  let {from, to, empty} = state.selection
  if (empty) return type.isInSet(state.storedMarks || state.doc.marksAt(from))
  else return state.doc.rangeHasMark(from, to, type)
}

function markItem(markType, options) {
  let passedOptions = {
    active(state) { return markActive(state, markType) }
  }
  for (let prop in options) passedOptions[prop] = options[prop]
  return cmdItem(toggleMark(markType), passedOptions)
}

function linkItem(markType) {
  return markItem(markType, {
    title: "Add or remove link",
    icon: icons.link,
    run(state, onAction, view) {
      if (markActive(state, markType)) {
        toggleMark(markType)(state, onAction)
        return true
      }
      openPrompt({
        title: "Create a link",
        fields: {
          href: new TextField({
            label: "Link target",
            required: true,
            clean: (val) => {
              if (!/^https?:\/\//i.test(val))
                val = 'http://' + val
              return val
            }
          }),
          title: new TextField({label: "Title"})
        },
        callback(attrs) {
          toggleMark(markType, attrs)(view.state, view.props.onAction)
        }
      })
    }
  })
}

function fetchCharacter(characterList, cId) {
    const matches = characterList.filter(c => c.id === parseInt(cId, 10));
    return matches.length ? matches[0] : null;
}

function markItemPrivate(markType) {
    return markItem(markType, {
        title: "Private text",
        run(state, onAction, view) {
            let {node} = state.selection, attrs = markType && node &&
                    node.type == markType && node.attrs;

            openPrompt({
                title: "Choose the characters who will read the private text",
                fields: {
                    targetCharacters: new MultiSelectField({
                        label: "Targets",
                        required: true,
                        selected: (attrs && attrs.mentionTargets) || [],
                        options: view.props.participants.map(c => ({value: c.id,
                                                                    label: c.name}))
                    })
                },
                // FIXME this (and similar uses) won't have the current state
                // when it runs, leading to problems in, for example, a
                // collaborative setup
                callback(attrs) {
                    if (markActive(state, markType)) {
                        toggleMark(markType)(state, onAction);
                        return;
                    }
                    const targetCharacters =
                              attrs.targetCharacters.map(c => fetchCharacter(view.props.participants, c));
                    toggleMark(markType, {mentionTargets: targetCharacters})(state, onAction);
                }
            });
        }
    });
}

function wrapListItem(nodeType, options) {
  return cmdItem(wrapInList(nodeType, options.attrs), options)
}

// :: (Schema) → Object
// Given a schema, look for default mark and node types in it and
// return an object with relevant menu items relating to those marks:
//
// **`toggleStrong`**`: MenuItem`
//   : A menu item to toggle the [strong mark](#schema-basic.StrongMark).
//
// **`toggleEm`**`: MenuItem`
//   : A menu item to toggle the [emphasis mark](#schema-basic.EmMark).
//
// **`toggleCode`**`: MenuItem`
//   : A menu item to toggle the [code font mark](#schema-basic.CodeMark).
//
// **`toggleLink`**`: MenuItem`
//   : A menu item to toggle the [link mark](#schema-basic.LinkMark).
//
// **`insertImage`**`: MenuItem`
//   : A menu item to insert an [image](#schema-basic.Image).
//
// **`wrapBulletList`**`: MenuItem`
//   : A menu item to wrap the selection in a [bullet list](#schema-list.BulletList).
//
// **`wrapOrderedList`**`: MenuItem`
//   : A menu item to wrap the selection in an [ordered list](#schema-list.OrderedList).
//
// **`wrapBlockQuote`**`: MenuItem`
//   : A menu item to wrap the selection in a [block quote](#schema-basic.BlockQuote).
//
// **`makeParagraph`**`: MenuItem`
//   : A menu item to set the current textblock to be a normal
//     [paragraph](#schema-basic.Paragraph).
//
// **`makeCodeBlock`**`: MenuItem`
//   : A menu item to set the current textblock to be a
//     [code block](#schema-basic.CodeBlock).
//
// **`insertTable`**`: MenuItem`
//   : An item to insert a [table](#schema-table).
//
// **`addRowBefore`**, **`addRowAfter`**, **`removeRow`**, **`addColumnBefore`**, **`addColumnAfter`**, **`removeColumn`**`: MenuItem`
//   : Table-manipulation items.
//
// **`makeHead[N]`**`: MenuItem`
//   : Where _N_ is 1 to 6. Menu items to set the current textblock to
//     be a [heading](#schema-basic.Heading) of level _N_.
//
// **`insertHorizontalRule`**`: MenuItem`
//   : A menu item to insert a horizontal rule.
//
// The return value also contains some prefabricated menu elements and
// menus, that you can use instead of composing your own menu from
// scratch:
//
// **`insertMenu`**`: Dropdown`
//   : A dropdown containing the `insertImage` and
//     `insertHorizontalRule` items.
//
// **`typeMenu`**`: Dropdown`
//   : A dropdown containing the items for making the current
//     textblock a paragraph, code block, or heading.
//
// **`fullMenu`**`: [[MenuElement]]`
//   : An array of arrays of menu elements for use as the full menu
//     for, for example the [menu bar](#menu.MenuBarEditorView).
function buildMenuItems(schema) {
  let r = {}, type
  if (type = schema.marks.strong)
    r.toggleStrong = markItem(type, {title: "Toggle strong style", icon: icons.strong})
  if (type = schema.marks.em)
    r.toggleEm = markItem(type, {title: "Toggle emphasis", icon: icons.em})
  if (type = schema.marks.code)
    r.toggleCode = markItem(type, {title: "Toggle code font", icon: icons.code})
  if (type = schema.marks.link)
    r.toggleLink = linkItem(type)

  if (type = schema.nodes.image)
    r.insertImage = insertImageItem(type)
  if (type = schema.marks.mention)
    r.togglePrivate = markItemPrivate(type, {title: "Mark text as private", icon: 'Private text'})
  if (type = schema.nodes.bullet_list)
    r.wrapBulletList = wrapListItem(type, {
      title: "Wrap in bullet list",
      icon: icons.bulletList
    })
  if (type = schema.nodes.ordered_list)
    r.wrapOrderedList = wrapListItem(type, {
      title: "Wrap in ordered list",
      icon: icons.orderedList
    })
  if (type = schema.nodes.blockquote)
    r.wrapBlockQuote = wrapItem(type, {
      title: "Wrap in block quote",
      icon: icons.blockquote
    })
  if (type = schema.nodes.paragraph)
    r.makeParagraph = blockTypeItem(type, {
      title: "Change to paragraph",
      label: "Plain"
    })
  if (type = schema.nodes.code_block)
    r.makeCodeBlock = blockTypeItem(type, {
      title: "Change to code block",
      label: "Code"
    })
  if (type = schema.nodes.heading)
    for (let i = 1; i <= 10; i++)
      r["makeHead" + i] = blockTypeItem(type, {
        title: "Change to heading " + i,
        label: "Level " + i,
        attrs: {level: i}
      })
  if (type = schema.nodes.horizontal_rule) {
    let hr = type
    r.insertHorizontalRule = new MenuItem({
      title: "Insert horizontal rule",
      label: "Horizontal rule",
      select(state) { return canInsert(state, hr) },
      run(state, dispatch) { dispatch(state.tr.replaceSelectionWith(hr.create())) }
    })
  }

  let cut = arr => arr.filter(x => x)
  r.insertMenu = new Dropdown(cut([r.insertImage, r.insertHorizontalRule, r.insertTable]), {label: "Insert"})
  r.typeMenu = new Dropdown(cut([r.makeParagraph, r.makeCodeBlock, r.makeHead1 && new DropdownSubmenu(cut([
    r.makeHead1, r.makeHead2, r.makeHead3, r.makeHead4, r.makeHead5, r.makeHead6
  ]), {label: "Heading"})]), {label: "Type..."})
  let tableItems = cut([r.addRowBefore, r.addRowAfter, r.removeRow, r.addColumnBefore, r.addColumnAfter, r.removeColumn])
  if (tableItems.length)
    r.tableMenu = new Dropdown(tableItems, {label: "Table"})

    r.inlineMenu = [cut([r.toggleStrong, r.toggleEm, r.toggleCode, r.toggleLink]), [r.togglePrivate], [r.insertMenu]]
  r.blockMenu = [cut([r.typeMenu, r.tableMenu, r.wrapBulletList, r.wrapOrderedList, r.wrapBlockQuote, joinUpItem,
                      liftItem, selectParentNodeItem])]
  r.fullMenu = r.inlineMenu.concat(r.blockMenu).concat([[undoItem, redoItem]])

  return r
}
exports.buildMenuItems = buildMenuItems
