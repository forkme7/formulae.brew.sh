# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2016-2017, Sebastian Staudt

class ApiController < FormulaeController

  before_action :ensure_json
  skip_before_action :ensure_html

  def version
    @formula = self.formulae.where(name: params[:formula_id]).first
    if @formula.nil?
      @formula = self.formulae.all_in(aliases: [params[:formula_id]]).first
      unless @formula.nil?
        redirect_to repository_formula_version_path(@formula.repository.name, @formula)
        return
      end
      raise Mongoid::Errors::DocumentNotFound.new(Formula, [], params[:formula_id])
    end

    return unless stale? @formula.revisions.first.sha, public: true

    respond_to do |format|
      format.json do
        render json: {
          stable: @formula.stable_version,
          devel: @formula.devel_version,
          head: @formula.head_version
        }
      end
    end
  end

  private

  def ensure_json
    head 406 unless request.format == :json
  end

end
