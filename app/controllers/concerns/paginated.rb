# frozen_string_literal: true

module Paginated
  extend ActiveSupport::Concern

  Page = Data.define(:records, :current, :total, :count) do
    def first? = current <= 1
    def last? = current >= total
    def prev_page = current - 1
    def next_page = current + 1
  end

  private

    PER_PAGE = 25

    def paginate(scope, per: PER_PAGE)
      count = scope.count
      total = [ (count.to_f / per).ceil, 1 ].max
      current = params[:page].to_i.clamp(1, total)
      records = scope.limit(per).offset((current - 1) * per)

      Page.new(records: records, current: current, total: total, count: count)
    end
end
