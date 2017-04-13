# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2017, Sebastian Staudt

class ApplicationController < ActionController::Base

  class RepositoryUnavailable < StandardError; end

  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: :forbidden

  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
  rescue_from RepositoryUnavailable do
    error_page :service_unavailable
  end

  def index
    main_page

    respond_to do |format|
      format.html { render 'application/index' }
      format.any { render nothing: true, status: :not_found }
    end

    fresh_when etag: Repository.core.sha, public: true
  end

  def error_page(status = :internal_server_error)
    view = 'application/%d' % [ Rack::Utils::SYMBOL_TO_STATUS_CODE[status] ]

    respond_to do |format|
      format.html { render view, status: status }
      format.any { render nothing: true, status: status }
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
      format.any { head :not_found }
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
    @taps = Repository.only(:_id, :date, :letters, :name, :sha, :updated_at).
            current_taps.order_by([:name, :asc]).to_a
    @taps = ([ Repository.core ] + @taps).uniq

    @added = Formula.where(removed: false).
            with_size(revision_ids: 1).
            order_by(%i{date desc}).
            only(:_id, :devel_version, :head_version, :name, :repository_id, :stable_version).
            limit 5

    @updated = Formula.where(removed: false).
            not.with_size(revision_ids: 1).
            order_by(%i{date desc}).
            only(:_id, :devel_version, :head_version, :name, :repository_id, :stable_version).
            limit 5

    @removed = Formula.where(removed: true).
            order_by(%i{date desc}).
            only(:_id, :name, :repository_id).
            limit 5
  end

end
