# frozen_string_literal: true

class Admin::HeaderAliasesController < Admin::BaseController
  before_action :set_header_alias, only: [ :show, :edit, :update, :destroy ]

  def index
    aliases = HeaderAlias.order(:field, :pattern)
    aliases = aliases.where("pattern LIKE ?", "%#{params[:q].strip.upcase}%") if params[:q].present?
    aliases = aliases.where(field: params[:field]) if params[:field].present?
    @header_aliases = aliases
  end

  def new
    @header_alias = HeaderAlias.new
  end

  def create
    @header_alias = HeaderAlias.new(header_alias_params)

    if @header_alias.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_root_path, notice: t("flash.admin.header_aliases.created") }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
  end

  def edit
  end

  def update
    if @header_alias.update(header_alias_params)
      render @header_alias
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @header_alias.destroy
    redirect_to admin_root_path, notice: t("flash.admin.header_aliases.deleted")
  end

  private

    def set_header_alias
      @header_alias = HeaderAlias.find(params[:id])
    end

    def header_alias_params
      params.expect(header_alias: [ :field, :pattern ])
    end
end
