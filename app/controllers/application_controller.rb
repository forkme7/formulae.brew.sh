# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found

  def index
    main_page

    respond_to do |format|
      format.html { render 'application/index' }
      format.any { render nothing: true, status: :not_found }
    end

    fresh_when etag: Repository.core.sha, public: true
  end

  def error_page
    Airbrake.notify $! if defined? Airbrake

    respond_to do |format|
      format.html { render 'application/500', status: :internal_server_error }
      format.any { render nothing: true, status: :internal_server_error }
    end

    headers.delete 'ETag'
    expires_in 5.minutes
  end

  def forbidden
    respond_to do |format|
      format.any { render nothing: true, status: :forbidden }
    end
  end

  def not_found
    flash.now[:error] = 'The page you requested does not exist.'
    main_page

    respond_to do |format|
      format.html { render 'application/index', status: :not_found }
      format.any { render nothing: true, status: :not_found }
    end

    headers.delete 'ETag'
    expires_in 5.minutes
  end

  def sitemap
    @repository = Repository.only(:_id, :sha, :updated_at).core

    respond_to do |format|
      format.xml
    end

    fresh_when etag: @repository.sha, public: true
  end

  private

  def main_page
    @alt_repos = Repository.only(:_id, :date, :name, :sha, :updated_at).
            order_by([:name, :asc]).
            where(:name.ne => Repository::MAIN).to_a
    @repository = @alt_repos.find { |repo| repo.name == Repository::CORE }
    @alt_repos -= [ @repository ]

    @added = @repository.formulae.with_size(revision_ids: 1).
            order_by(%i{date desc}).
            only(:_id, :devel_version, :head_version, :name, :repository_id, :stable_version).
            limit 5

    @updated = @repository.formulae.where(removed: false).
            not.with_size(revision_ids: 1).
            order_by(%i{date desc}).
            only(:_id, :devel_version, :head_version, :name, :repository_id, :stable_version).
            limit 5

    @removed = @repository.formulae.where(removed: true).
            order_by(%i{date desc}).
            only(:_id, :name, :repository_id).
            limit 5
  end

end
