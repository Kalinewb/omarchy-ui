.pragma library

// Engine error code -> the sentence a person reads, from one table per plugin
// (seeded from omarchy-egpu common/Errors.js, which had the right idea).
//
//   var errors = Errors.create({
//     sentences: { not_connected: "The eGPU is not connected." },
//     exits: { 126: "Permission declined" },   // exit codes that mean one thing for every verb
//     notes: { needs_relogin: "..." },          // conditions that are not errors but need a sentence
//   })
//   errors.message(code)    the sentence, or "Something went wrong." for a code the table has
//                           never heard of (an empty line would read as success)
//   errors.details(code)    the code itself, for the "Details" line under a UNotice;
//                           a code never reaches the surface any other way
//   errors.forResult(r)     r is {ok, code, error}: exit codes win over the JSON that came with them
//   errors.note(id)

var FALLBACK = "Something went wrong."

function create(spec) {
  spec = spec || {}
  var sentences = spec.sentences || {}
  var exits = spec.exits || {}
  var notes = spec.notes || {}
  var fallback = spec.fallback || FALLBACK

  function text(code) { return String(code === undefined || code === null ? "" : code) }
  function has(table, key) { return Object.prototype.hasOwnProperty.call(table, key) }

  function message(code) {
    var c = text(code)
    if (c === "") return ""
    return has(sentences, c) ? sentences[c] : fallback
  }
  return {
    message: message,
    details: function(code) { return text(code) },
    note: function(id) { return has(notes, id) ? notes[id] : "" },
    forResult: function(result) {
      if (!result || result.ok) return ""
      if (has(exits, result.code)) return exits[result.code]
      return message(result.error || ("exit " + result.code))
    }
  }
}
