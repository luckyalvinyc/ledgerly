# frozen_string_literal: true

require "test_helper"

class Admin::HeaderAliasesTest < ActionDispatch::IntegrationTest
  setup { admin_sign_in }

  test "an admin sees the header aliases" do
    get admin_root_path

    assert_response :success
    assert_select ".alias-row .mono", text: "DATE"
  end

  test "an admin searches aliases by pattern" do
    get admin_root_path, params: { q: "money" }

    assert_response :success
    assert_select ".alias-row .mono", text: "MONEY IN"
    assert_select ".alias-row .mono", text: "DATE", count: 0
  end

  test "an admin filters aliases by field" do
    get admin_root_path, params: { field: "date" }

    assert_response :success
    assert_select ".alias-row .mono", text: "DATE"
    assert_select ".alias-row .mono", text: "AMOUNT", count: 0
  end

  test "an admin adds a header alias, stored normalized" do
    assert_difference -> { HeaderAlias.count } => 1 do
      post admin_header_aliases_path, params: { header_alias: { field: "amount", pattern: "value" } }
    end

    assert_redirected_to admin_root_path
    assert HeaderAlias.exists?(field: "amount", pattern: "VALUE")
  end

  test "an admin adds an alias inline" do
    assert_difference -> { HeaderAlias.count } => 1 do
      post admin_header_aliases_path,
           params: { header_alias: { field: "amount", pattern: "inline" } },
           as: :turbo_stream
    end

    assert_response :success
    assert_match "INLINE", response.body
  end

  test "an admin edits an alias inline" do
    header_alias = header_aliases(:amount_amount)

    patch admin_header_alias_path(header_alias), params: { header_alias: { pattern: "amt" } }

    assert_response :success
    assert_equal "AMT", header_alias.reload.pattern
  end

  test "an admin removes a header alias" do
    assert_difference -> { HeaderAlias.count } => -1 do
      delete admin_header_alias_path(header_aliases(:amount_amount))
    end

    assert_redirected_to admin_root_path
  end
end
