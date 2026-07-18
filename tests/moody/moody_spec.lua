local math_mod = require("moody.math")
local utils = require("moody.utils")
local config = require("moody.config")

describe("moody.math", function()
  describe("int_to_hex_string", function()
    it("formats an integer as #RRGGBB", function()
      assert.equals("#000000", math_mod.int_to_hex_string(0))
      assert.equals("#0000ff", math_mod.int_to_hex_string(255))
      assert.equals("#ffffff", math_mod.int_to_hex_string(0xffffff))
    end)

    it("passes nil through unchanged", function()
      assert.is_nil(math_mod.int_to_hex_string(nil))
    end)
  end)

  describe("rgb", function()
    it("splits a hex string into channels", function()
      assert.same({ 255, 255, 255 }, math_mod.rgb("#ffffff"))
      assert.same({ 0, 0, 0 }, math_mod.rgb("#000000"))
      assert.same({ 18, 52, 86 }, math_mod.rgb("#123456"))
    end)
  end)

  describe("blend", function()
    it("returns the background at alpha 0 and foreground at alpha 1", function()
      assert.equals("#000000", math_mod.blend("#ffffff", 0, "#000000"))
      assert.equals("#ffffff", math_mod.blend("#ffffff", 1, "#000000"))
    end)

    it("mixes evenly at alpha 0.5", function()
      assert.equals("#808080", math_mod.blend("#ffffff", 0.5, "#000000"))
    end)

    it("accepts a hex-string alpha", function()
      assert.equals("#ffffff", math_mod.blend("#ffffff", "ff", "#000000"))
    end)
  end)
end)

describe("moody.utils", function()
  describe("switch", function()
    it("returns the value for a matched key", function()
      assert.equals(1, utils.switch("a", { a = 1, b = 2, default = 9 }))
    end)

    it("falls back to default for an unmatched key", function()
      assert.equals(9, utils.switch("z", { a = 1, default = 9 }))
    end)

    it("returns nil when there is no match and no default", function()
      assert.is_nil(utils.switch("z", { a = 1 }))
    end)
  end)
end)

describe("moody.config.validate", function()
  it("accepts nil and an empty table", function()
    assert.is_true(config.validate(nil))
    assert.is_true(config.validate({}))
  end)

  it("rejects a non-table options value", function()
    assert.is_false(config.validate("nope"))
  end)

  it("rejects a wrong top-level type", function()
    local ok, err = config.validate({ bold_line_number = "yes" })
    assert.is_false(ok)
    assert.is_truthy(err:match("bold_line_number"))
  end)

  it("accepts valid hex colors", function()
    assert.is_true(config.validate({ colors = { normal = "#00BFFF" } }))
  end)

  it("rejects non-hex colors", function()
    local ok, err = config.validate({ colors = { normal = "red" } })
    assert.is_false(ok)
    assert.is_truthy(err:match("colors.normal"))
  end)

  it("accepts blends within [0, 1]", function()
    assert.is_true(config.validate({ blends = { normal = 0.5 } }))
  end)

  it("rejects out-of-range blends", function()
    assert.is_false(config.validate({ blends = { normal = 2 } }))
  end)

  it("accepts the shipped defaults", function()
    assert.is_true(config.validate(config.defaults))
  end)
end)

describe("moody.config.trigger_mode", function()
  local win

  before_each(function()
    config.__setup({})
    win = vim.api.nvim_get_current_win()
    config._applied_ns[win] = nil
  end)

  it("applies the operator namespace on entering operator-pending", function()
    config.trigger_mode({ match = "n:no" }, win)
    assert.equals(config.ns_operator, config._applied_ns[win])
  end)

  it("restores the normal namespace on returning from operator-pending", function()
    config.trigger_mode({ match = "n:no" }, win)
    config.trigger_mode({ match = "no:n" }, win)
    assert.equals(config.ns_normal, config._applied_ns[win])
  end)

  it("self-heals a stuck window from the actual mode when event is nil", function()
    -- Simulate a stale operator colour that no ModeChanged corrected (e.g. the
    -- no:n fired while a disabled popup was the current window).
    config.trigger_mode({ match = "n:no" }, win)
    assert.equals(config.ns_operator, config._applied_ns[win])
    -- SafeState path: no event, reads the real mode (normal in a test run).
    config.trigger_mode(nil, win)
    assert.equals(config.ns_normal, config._applied_ns[win])
  end)

  it("resets unknown modes to the global namespace", function()
    config.trigger_mode({ match = "n:zz" }, win)
    assert.equals(0, config._applied_ns[win])
  end)
end)
