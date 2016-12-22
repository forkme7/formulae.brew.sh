# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

require 'text'

class FormulaeController < ApplicationController

  before_action :select_repository
  before_action :letters, only: [ :browse, :search ]

  def browse
    letter = params[:letter]
    @title = "Browse formulae – #{letter.upcase}"
    @title << " – #{@repository.name}" unless @repository.core?

    @formulae = @repository.formulae.letter(letter).
            where(removed: false).order_by([:name, :asc]).
            page(params[:page]).per 30

    fresh_when etag: @repository.sha, public: true
  end

  def feed
    @revisions = @repository.revisions.without_bot.order_by([:date, :desc]).limit 50

    respond_to do |format|
      format.atom
    end

    fresh_when etag: @repository.sha, public: true
  end

  def search
    return not_found if params[:search].nil? || params[:search].empty?

    term = params[:search].force_encoding 'UTF-8'
    @title = "Search for: #{term}"
    @title << " in #{@repository.name}" unless @repository.core?
    search_term = /#{Regexp.escape term}/i
    @formulae = @repository.formulae.and(removed: false, :$or => [
            { aliases: search_term },
            { description: search_term },
            { name: search_term }
    ])

    if @formulae.size == 1 && term == @formulae.first.name
      if @repository.core?
        redirect_to formula_path(@formulae.first)
      else
        redirect_to repository_formula_path(@repository.name, @formulae.first)
      end
      return
    end

    @formulae = @formulae.sort_by do |formula|
      Text::Levenshtein.distance(formula.name, term) +
      Text::Levenshtein.distance(formula.name[0..term.size - 1], term)
    end
    @formulae = Kaminari.paginate_array(@formulae).
            page(params[:page]).per 30

    respond_to do |format|
      format.html { render 'formulae/browse' }
    end

    fresh_when etag: @repository.sha, public: true
  end

  def show
    formula_id = "#{repository_id}/#{params[:id]}"
    @formula = Formula.find formula_id
    if @formula.nil?
      formula = @repository.formulae.all_in(aliases: [params[:id]]).first
      unless formula.nil?
        if @repository.core?
          redirect_to formula
        else
          redirect_to repository_formula_path(@repository.name, formula)
        end
        return
      end
      raise Mongoid::Errors::DocumentNotFound.new(Formula, [], params[:id])
    end
    @title = @formula.name.dup
    @title << " – #{@repository.name}" unless @repository.core?
    @revisions = @formula.revisions.without_bot.includes(:author).order_by %i{date desc}

    fresh_when etag: @revisions.first.sha, public: true
  end

  private

  def letters
    @letters = ('A'..'Z').select do |letter|
      @repository.formulae.letter(letter).where(removed: false).exists?
    end
  end

  def repository_id
    @repository_id ||= params[:repository_id] || Repository::CORE
  end

  def select_repository
    core_repo_url = "/repos/#{Repository::CORE}/"
    if request.url.match core_repo_url
      redirect_to '/' + request.url.split(core_repo_url, 2)[1]
      return
    end

    @repository = Repository.where(name: /^#{repository_id}$/i).
            only(:_id, :name, :sha, :updated_at).first
    if @repository.nil?
      raise Mongoid::Errors::DocumentNotFound.new Repository, [], repository_id
    end

    if @repository.name != repository_id
      redirect_to request.url.sub "/repos/#{repository_id}", "/repos/#{@repository.name}"
    end
  end

end
