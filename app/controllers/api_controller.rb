# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2016, Sebastian Staudt

class ApiController < FormulaeController

  def version
    formula_id = "#{repository_id}/#{params[:formula_id]}"
    @formula = Formula.find formula_id
    if @formula.nil?
      formula = @repository.formulae.all_in(aliases: [params[:formula_id]]).first
      unless formula.nil?
        if @repository.main?
          redirect_to formula_version_path(formula)
        else
          redirect_to repository_formula_version_path(@repository.name, formula)
        end
        return
      end
      raise Mongoid::Errors::DocumentNotFound.new(Formula, [], params[:formula_id])
    end

    if stale? @formula.revisions.first.sha, public: true
      respond_to do |format|
        format.json do
          render json: {
            stable: @formula.stable_version,
            devel: @formula.devel_version,
            head: @formula.head_version
          }.to_json
        end
      end
    end
  end

end
