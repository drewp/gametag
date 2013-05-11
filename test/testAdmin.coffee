Browser = require("zombie");
assert = require("assert")

root = "http://bang:3200/"

browser = new Browser(
)
browser.on "error", (error) ->
  console.error(error)

describe "the admin page", () ->
  it "should never have a uri without a scheme", (done2) =>
    browser.visit(root).then(() =>
      assert(not browser.html().match(/// "/ ///))
      done2()
    ).fail(done2)

