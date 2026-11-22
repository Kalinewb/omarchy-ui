import QtQuick
import QtTest
import "../../../ui"

// What the kit's components do with real key presses, under qmltestrunner
// (dev/test.sh): activation keys, arrow keys, and above all Esc, which closes
// in order: an edit, a tip, an open pick, a modal, then goes back, then closes.
Item {
  id: root
  width: 640
  height: 480

  StubTheme { id: stub }
  property int closes: 0
  property int backs: 0

  // The page-level router, as a plugin has it.
  Component {
    id: pageC
    UKeys {
      id: page
      anchors.fill: parent
      focus: true
      level: "back"
      open: true
      onEscaped: root.backs++
      onCloseRequested: root.closes++
    }
  }

  Component { id: buttonC; UButton { theme: stub; text: "Go" } }
  Component { id: iconC; UButton { theme: stub; glyph: "\u270e"; name: "Rename" } }
  Component { id: switchC; USwitch { theme: stub; label: "Dark" } }
  Component { id: segC; USegmented { theme: stub; label: "Scope"; value: "b"; options: [{ value: "a", label: "A" }, { value: "b", label: "B" }, { value: "c", label: "C" }] } }
  Component { id: stepC; UStepper { theme: stub; label: "Radius"; from: 0; to: 3; value: 2 } }
  Component { id: pickC; UPick { theme: stub; label: "Mod"; value: "b"; options: [{ value: "a", label: "A" }, { value: "b", label: "B" }, { value: "c", label: "C" }] } }
  Component { id: fieldC; UField { theme: stub; label: "Name"; value: "Ana"; width: 200 } }
  Component { id: secretC; UField { theme: stub; label: "Password"; secret: true; width: 200 } }
  Component { id: backC; UBack { theme: stub } }
  Component { id: closeC; UClose { theme: stub } }
  Component { id: confirmC; UConfirmSheet { theme: stub; width: 400; sentence: "Remove Ana? Her face data is erased."; verb: "Remove" } }
  Component { id: noticeC; UNotice { theme: stub; width: 400; text: "The camera is busy." } }
  Component { id: toastC; UToast { theme: stub } }
  Component { id: ringC; URing { theme: stub } }
  Component { id: rowC; URow { theme: stub; label: "Row"; width: 300; USwitch { theme: stub; label: "x" } } }
  Component {
    id: itemC
    URow {
      theme: stub; width: 400; clickable: true
      icon: "\u25cf"; label: "Work"; detail: "3 apps, last used today"; badge: "Default"; current: true
      trailing: Row {
        spacing: 4
        UButton { theme: stub; glyph: "+"; name: "Add to Work" }
        UButton { theme: stub; glyph: "\u2715"; name: "Remove Work"; kind: "destructive" }
      }
    }
  }
  Component { id: stackedC; URow { theme: stub; label: "Row"; variant: "stacked"; width: 300; UField { theme: stub; label: "f"; width: parent.width } } }

  TestCase {
    name: "kit"
    when: windowShown

    function init() { root.closes = 0; root.backs = 0; stub.reduced = false }
    function page() { return createTemporaryObject(pageC, root) }
    function typeText(t) { for (var i = 0; i < t.length; i++) keyClick(t[i]) }
    function focused(item) { item.forceActiveFocus(); verify(item.activeFocus, "takes focus") }

    // ------------------------------------------------------------ activation keys
    function test_button_keys() {
      var b = createTemporaryObject(buttonC, root)
      var spy = createTemporaryObject(spyC, root, { target: b, signalName: "clicked" })
      focused(b)
      keyClick(Qt.Key_Return); keyClick(Qt.Key_Enter); keyClick(Qt.Key_Space)
      compare(spy.count, 3, "Return, Enter and Space each click")
      keyClick(Qt.Key_Left)
      compare(spy.count, 3, "an arrow does not")
    }
    Component { id: spyC; SignalSpy { } }

    function test_icon_button_is_a_named_24_px_button_with_the_same_keys() {
      var b = createTemporaryObject(iconC, root), t = createTemporaryObject(buttonC, root)
      verify(b.iconOnly && !t.iconOnly)
      compare(b.Accessible.name, "Rename"); compare(b.Accessible.role, Accessible.Button)
      verify(b.width >= stub.minHit && b.height >= stub.minHit, "24 px or more: " + b.width + "x" + b.height)
      compare(b.width, b.height, "a square")
      compare(b.height, t.height, "as tall as the text button beside it")
      var p = createTemporaryObject(iconC, root, { kind: "primary" })
      verify(p.height >= stub.rowHeight && p.isPrimary, "a primary icon button keeps the row height the walk asks of one")
      var spy = createTemporaryObject(spyC, root, { target: b, signalName: "clicked" })
      focused(b)
      keyClick(Qt.Key_Return); keyClick(Qt.Key_Space)
      compare(spy.count, 2, "Enter and Space click it")
      var tip = b.children[b.children.length - 1]
      wait(400)
      verify(tip.shown && tip.text === "Rename", "its name is the tooltip")
      b.enabled = false
      verify(!b.activeFocus, "disabled: not a tab stop")
    }

    function test_switch_toggles_on_space_and_return() {
      var s = createTemporaryObject(switchC, root)
      var spy = createTemporaryObject(spyC, root, { target: s, signalName: "toggled" })
      focused(s)
      keyClick(Qt.Key_Space); keyClick(Qt.Key_Return)
      compare(spy.count, 2)
      compare(s.Accessible.name, "Dark")
      verify(s.height >= 24 && s.width >= 24, "a 24 px hit target around a 22 px track")
    }

    function test_segmented_arrows_move_the_choice_and_stop_at_the_ends() {
      var s = createTemporaryObject(segC, root)
      var spy = createTemporaryObject(spyC, root, { target: s, signalName: "picked" })
      focused(s)
      keyClick(Qt.Key_Right)
      compare(spy.count, 1); compare(spy.signalArguments[0][0], "c")
      s.value = "c"
      keyClick(Qt.Key_Right)
      compare(spy.count, 1, "no wrap past the last")
      keyClick(Qt.Key_Left)
      compare(spy.count, 2); compare(spy.signalArguments[1][0], "b")
      s.value = "a"
      keyClick(Qt.Key_Left)
      compare(spy.count, 2, "no wrap before the first")
    }

    function test_stepper_left_right_clamped() {
      var s = createTemporaryObject(stepC, root)
      var spy = createTemporaryObject(spyC, root, { target: s, signalName: "modified" })
      focused(s)
      keyClick(Qt.Key_Right)
      compare(spy.count, 1); compare(spy.signalArguments[0][0], 3)
      s.value = 3
      keyClick(Qt.Key_Right)
      compare(spy.count, 1, "at the top it stays")
      keyClick(Qt.Key_Left)
      compare(spy.signalArguments[1][0], 2)
      s.value = 0
      keyClick(Qt.Key_Left)
      compare(spy.count, 2, "at the bottom it stays")
      keyClick(Qt.Key_Up)
      compare(spy.count, 2, "Up and Down are the page's, not the stepper's")
    }

    function test_back_and_close_activate() {
      var b = createTemporaryObject(backC, root), c = createTemporaryObject(closeC, root)
      var sb = createTemporaryObject(spyC, root, { target: b, signalName: "activated" })
      var sc = createTemporaryObject(spyC, root, { target: c, signalName: "activated" })
      compare(b.Accessible.name, "Back"); compare(c.Accessible.name, "Close")
      focused(b); keyClick(Qt.Key_Return); compare(sb.count, 1)
      focused(c); keyClick(Qt.Key_Space); compare(sc.count, 1)
    }

    // ------------------------------------------------------------ Esc, in order
    function test_esc_at_the_root_closes_the_panel() {
      var p = page(); focused(p)
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1, "back is open at depth > 0, so Esc goes back")
      compare(root.closes, 0)
      p.open = false
      keyClick(Qt.Key_Escape)
      compare(root.closes, 1, "with nothing open it asks to close")
    }

    function test_esc_closes_an_open_pick_before_anything_else() {
      var p = page()
      var pick = createTemporaryObject(pickC, p)
      focused(pick)
      keyClick(Qt.Key_Down)
      verify(pick.open, "Down opens it")
      keyClick(Qt.Key_Down)
      compare(pick.cursor, 2)
      keyClick(Qt.Key_Up); keyClick(Qt.Key_Up)
      compare(pick.cursor, 0)
      keyClick(Qt.Key_Escape)
      verify(!pick.open, "Esc closes the pick")
      compare(root.backs, 0, "and goes no further")
      compare(root.closes, 0)
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1, "the next Esc is the page's")
    }

    function test_pick_enter_picks_and_closes() {
      var p = page()
      var pick = createTemporaryObject(pickC, p)
      var spy = createTemporaryObject(spyC, root, { target: pick, signalName: "picked" })
      focused(pick)
      keyClick(Qt.Key_Return)
      verify(pick.open)
      keyClick(Qt.Key_Down); keyClick(Qt.Key_Return)
      compare(spy.count, 1); compare(spy.signalArguments[0][0], "c")
      verify(!pick.open)
      compare(pick.z, 0, "and no longer above its siblings")
    }

    function test_field_enter_commits_esc_reverts_then_the_panel() {
      var p = page()
      var f = createTemporaryObject(fieldC, p)
      var spy = createTemporaryObject(spyC, root, { target: f, signalName: "committed" })
      focused(f.input)
      f.input.text = "Anna"
      verify(f.dirty)
      keyClick(Qt.Key_Escape)
      compare(f.input.text, "Ana", "Esc reverts the edit")
      compare(root.backs + root.closes, 0, "and the page did not move")
      f.input.text = "Ben"
      keyClick(Qt.Key_Return)
      compare(spy.count, 1); compare(spy.signalArguments[0][0], "Ben")
      f.value = "Ben"
      verify(!f.dirty)
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1, "clean again: Esc is the page's")
    }

    function test_secret_field_is_masked_and_never_names_its_text() {
      var p = page()
      var f = createTemporaryObject(secretC, p)
      var plain = createTemporaryObject(fieldC, p)
      compare(plain.input.echoMode, TextInput.Normal, "a plain field shows its text")
      compare(plain.input.inputMethodHints, Qt.ImhNone)
      compare(f.input.echoMode, TextInput.Password)
      verify(f.input.inputMethodHints & Qt.ImhSensitiveData, "sensitive data: no history")
      verify(f.input.inputMethodHints & Qt.ImhNoPredictiveText, "no predictive text")
      focused(f.input)
      typeText("hunter2")
      compare(f.input.text, "hunter2", "the owner can still read it through committed")
      verify(f.input.displayText.indexOf("hunter") < 0 && f.input.displayText.length === 7, "what is drawn is bullets: " + f.input.displayText)
      compare(f.input.Accessible.name, "Password", "the name is the label, not the text")
      compare(f.input.Accessible.role, Accessible.EditableText)
      compare(f.Accessible.description, "", "no description carries the text")
      var spy = createTemporaryObject(spyC, root, { target: f, signalName: "committed" })
      keyClick(Qt.Key_Return)
      compare(spy.count, 1); compare(spy.signalArguments[0][0], "hunter2")
      f.clear()
      compare(f.input.text, "", "clear() wipes it")
    }

    function test_esc_in_a_secret_field_cancels_at_once_and_a_plain_one_reverts_first() {
      var p = page()
      var f = createTemporaryObject(secretC, p)
      focused(f.input)
      typeText("hunter2")
      verify(f.dirty, "there is typed text")
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1, "the first Esc is the page's, not the field's")
      compare(f.input.text, "hunter2", "the field does not revert: the owner clears it on close")
      f.clear()
      var g = createTemporaryObject(fieldC, p)
      focused(g.input)
      g.input.text = "Anna"
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1, "a plain field with an edit keeps Esc for itself (unchanged)")
      compare(g.input.text, "Ana")
    }

    function test_confirm_destructive_focuses_cancel_and_enter_does_not_fire_the_verb() {
      var p = page()
      var c = createTemporaryObject(confirmC, p, { destructive: true })
      var yes = createTemporaryObject(spyC, root, { target: c, signalName: "confirmed" })
      var no = createTemporaryObject(spyC, root, { target: c, signalName: "cancelled" })
      c.ask()
      verify(c.asking)
      keyClick(Qt.Key_Return)
      compare(yes.count, 0, "Enter does not fire a destructive verb")
      compare(no.count, 1, "initial focus was Cancel, so Enter cancelled")
      verify(!c.asking)
      c.ask()
      keyClick(Qt.Key_Tab)
      keyClick(Qt.Key_Return)
      compare(yes.count, 1, "Tab to the verb, then Enter, fires it")
    }

    function test_confirm_long_sentence_wraps_stays_compact_and_keeps_the_focus_on_cancel() {
      var long = "Remove Ana? Her face data is erased from this computer, every profile that shared it is renamed, and the windows she had open are closed. There is no undo."
      var p = page()
      var short = createTemporaryObject(confirmC, p, { destructive: true, width: 600 })
      verify(!short.stacked, "a short sentence stays beside the buttons")
      compare(short.height, stub.rowHeight, "and the sheet is one row high, as in 1.0")
      var c = createTemporaryObject(confirmC, p, { destructive: true, sentence: long, y: 100 })
      verify(long.length > 60, "past the 1.0 cap")
      verify(c.stacked, "it wraps with the buttons under it")
      var text = c.children[1].children[1]       // asker > the sentence (probe is the first child)
      compare(text.text, long)
      verify(text.lineCount > 1, "more than one line: " + text.lineCount)
      verify(text.contentWidth <= c.width, "inside the sheet's width")
      verify(c.height > 2 * stub.rowHeight && c.height < 8 * stub.rowHeight, "compact: " + c.height)
      var no = createTemporaryObject(spyC, root, { target: c, signalName: "cancelled" })
      var yes = createTemporaryObject(spyC, root, { target: c, signalName: "confirmed" })
      c.ask()
      keyClick(Qt.Key_Return)
      compare(yes.count, 0, "Enter still does not fire a destructive verb")
      compare(no.count, 1, "the focus was on Cancel")
      var q = createTemporaryObject(confirmC, p, { destructive: true, sentence: long, y: 300 })
      var no2 = createTemporaryObject(spyC, root, { target: q, signalName: "cancelled" })
      q.ask(); keyClick(Qt.Key_Escape)
      compare(no2.count, 1, "Esc is Cancel")
      compare(root.backs, 0)
    }

    function test_confirm_plain_verb_takes_the_focus_so_enter_confirms() {
      var p = page()
      var c = createTemporaryObject(confirmC, p, { destructive: false })
      var yes = createTemporaryObject(spyC, root, { target: c, signalName: "confirmed" })
      c.ask(); keyClick(Qt.Key_Return)
      compare(yes.count, 1)
    }

    function test_esc_in_a_confirm_is_cancel_and_comes_before_back() {
      var p = page()
      var c = createTemporaryObject(confirmC, p, { destructive: true })
      var no = createTemporaryObject(spyC, root, { target: c, signalName: "cancelled" })
      c.ask()
      keyClick(Qt.Key_Escape)
      compare(no.count, 1); verify(!c.asking)
      compare(root.backs, 0, "Esc was the modal's")
      keyClick(Qt.Key_Escape)
      compare(root.backs, 1)
    }

    function test_the_full_order_edit_tip_pick_modal_back_close() {
      var p = page()
      var pick = createTemporaryObject(pickC, p)
      var c = createTemporaryObject(confirmC, p, { destructive: true, y: 200 })
      var btn = createTemporaryObject(buttonC, p, { y: 300 })
      var tip = createTemporaryObject(tipC, btn)
      c.ask()                        // a modal
      pick.open = true               // a pick on top of it
      btn.hot = true; tip.armedHover = true   // and a tip shown
      verify(tip.shown)
      p.forceActiveFocus()
      keyClick(Qt.Key_Escape); verify(!tip.shown, "first the tip"); verify(pick.open && c.asking)
      keyClick(Qt.Key_Escape); verify(!pick.open, "then the pick"); verify(c.asking)
      keyClick(Qt.Key_Escape); verify(!c.asking, "then the modal")
      compare(root.backs, 0)
      keyClick(Qt.Key_Escape); compare(root.backs, 1, "then back")
      p.open = false
      keyClick(Qt.Key_Escape); compare(root.closes, 1, "then the panel closes")
    }
    Component { id: tipC; UTip { theme: stub; text: "Switches to the other profile." } }

    // ------------------------------------------------------------ tip, toast, ring, row
    function test_tip_waits_400_ms_on_hover_and_250_on_focus() {
      var btn = createTemporaryObject(buttonC, root)
      var tip = createTemporaryObject(tipC, btn)
      btn.hot = true
      wait(150); verify(!tip.shown, "not yet at 150 ms")
      wait(350); verify(tip.shown, "shown by 500 ms")
      btn.hot = false
      verify(!tip.shown, "leaving hides it")
      tip.target = btn
      focused(btn)
      wait(120); verify(!tip.shown, "not yet at 120 ms of focus")
      wait(250); verify(tip.shown, "shown by 370 ms of focus")
    }

    function test_foot_tip_writes_the_foot_line() {
      var btn = createTemporaryObject(buttonC, root)
      var tip = createTemporaryObject(tipC, btn, { placement: "foot", text: "Shows the date." })
      btn.hot = true
      wait(500)
      compare(stub.foot, "Shows the date.")
      btn.hot = false
      compare(stub.foot, "")
    }

    function test_toast_times_out_without_an_action_and_stays_with_one() {
      var plain = createTemporaryObject(toastC, root), act = createTemporaryObject(toastC, root)
      plain.show("Saved"); act.show("Ana removed", "Undo")
      verify(plain.shown && act.shown)
      wait(6300)
      verify(!plain.shown, "6 s, then it goes")
      verify(act.shown, "an action keeps it until acted on")
      var spy = createTemporaryObject(spyC, root, { target: act, signalName: "dismissed" })
      act.hide()
      compare(spy.count, 1); verify(!act.shown)
    }

    function test_notice_tones_have_their_own_mark_and_word() {
      var n = createTemporaryObject(noticeC, root)
      compare(n.glyph, "!"); compare(n.ink, stub.destructive); compare(n.Accessible.name, "Error: The camera is busy.")
      n.tone = "warn"; compare(n.glyph, "!"); compare(n.ink, stub.destructive)   // the old name reads as error
      n.tone = "warning"; compare(n.glyph, "▲"); compare(n.ink, stub.warning); compare(n.Accessible.name, "Warning: The camera is busy.")
      n.tone = "info"; compare(n.glyph, "i"); compare(n.ink, stub.label); compare(n.Accessible.name, "The camera is busy.")
    }

    function test_ring_turns_and_stops_under_reduced_motion() {
      var r = createTemporaryObject(ringC, root)
      var ring = r.children[0].children[0]    // Row > Item: the turning part
      verify(r.indeterminate)
      var a = ring.rotation; wait(250)
      verify(ring.rotation !== a, "it turns when motion is on")
      stub.reduced = true
      wait(50)
      var b = ring.rotation; wait(250)
      compare(ring.rotation, b, "and holds still under reduced motion")
    }

    function test_row_list_item_form_is_taller_marks_current_and_leaves_its_actions_clickable() {
      var plain = createTemporaryObject(rowC, root)
      var r = createTemporaryObject(itemC, root)
      compare(plain.height, stub.rowHeight, "a plain row is unchanged")
      verify(r.height > stub.rowHeight, "two lines make it taller: " + r.height)
      verify(r.lead >= stub.controlHeight, "the label starts after the icon column: " + r.lead)
      compare(r.Accessible.name, "Work")
      compare(r.Accessible.description, "3 apps, last used today. Default")
      verify(r.Accessible.selected, "the current one is selected for a screen reader")
      var spy = createTemporaryObject(spyC, root, { target: r, signalName: "activated" })
      mouseClick(r, 60, r.height / 2)
      compare(spy.count, 1, "a click on the row activates it")
      var add = r.trailing[0].children[0]
      var addSpy = createTemporaryObject(spyC, root, { target: add, signalName: "clicked" })
      var p = add.mapToItem(r, add.width / 2, add.height / 2)
      mouseClick(r, p.x, p.y)
      compare(addSpy.count, 1, "a click on a trailing button is the button's")
      compare(spy.count, 1, "and not the row's")
      r.current = false; r.badge = ""; r.detail = ""; r.icon = ""
      compare(r.height, stub.rowHeight + stub.sp.xs, "with the extras off it is as tall as any row with a button in its trailing slot")
    }

    function test_row_height_follows_density_and_stacked_grows() {
      var row = createTemporaryObject(rowC, root), st = createTemporaryObject(stackedC, root)
      compare(row.height, stub.rowHeight, "a row with a switch is one row high")
      verify(st.height > stub.rowHeight, "a stacked row is taller")
    }
  }
}
