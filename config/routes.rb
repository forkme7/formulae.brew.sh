# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

Rails.application.routes.draw do

  resources :repositories, path: 'repos', only: [],
            constraints: { repository_id: /[0-9A-Za-z_-]+?\/[0-9A-Za-z_-]+/ } do
    resources :formulae, only: :browse, path: 'browse' do
      get ':letter(/:page)', action: :browse, on: :collection,
          as: :letter,
          constraints: { letter: /[A-Za-z]/, page: /\d+/, format: 'html' }
    end

    resources :formulae, only: :browse, path: 'search' do
      get '(:search(/:page))', action: :search, on: :collection,
          as: :search,
          constraints: { page: /\d+/, search: /[^\/]+/, format: 'html' }
    end

    resources :formula, controller: :formulae, only: :show,
              constraints: { id: /.*/, format: 'html' } do
      get '/version', controller: :api, action: :version,
          constraints: { format: :json }, defaults: { format: :json }
    end

    scope format: true, :constraints => { :format => 'atom' } do
      get '/feed' => 'formulae#feed', as: :feed
    end
  end

  resources :formulae, only: :browse, path: 'browse' do
    get ':letter(/:page)', action: :browse, on: :collection,
        as: :letter,
        constraints: { letter: /[A-Za-z]/, page: /\d+/, format: 'html' }
  end

  resources :formulae, only: :browse, path: 'search' do
    get '(:search(/:page))', action: :search, on: :collection,
        as: :search,
        constraints: { page: /\d+/, search: /[^\/]+/, format: 'html' }
  end

  resources :formula, controller: :formulae, only: :show,
            constraints: { id: /.*/, format: 'html' } do
    get '/version', controller: :api, action: :version,
        constraints: { format: :json }, defaults: { format: :json }
  end

  scope format: true, :constraints => { :format => 'atom' } do
    get '/feed' => 'formulae#feed', as: :feed
  end

  scope format: true, :constraints => { :format => 'xml' } do
    get '/sitemap' => 'application#sitemap', as: :sitemap
  end

  root to: 'application#index'

  get '*url', to: 'application#not_found', format: false

  delete '/', to: 'application#forbidden', format: false
  delete '*url', to: 'application#forbidden', format: false
  post '/', to: 'application#forbidden', format: false
  post '*url', to: 'application#forbidden', format: false
  put '/', to: 'application#forbidden', format: false
  put '*url', to: 'application#forbidden', format: false
  match '/', via: :options, to: 'application#forbidden', format: false
  match '*url', via: :options, to: 'application#forbidden', format: false

end
