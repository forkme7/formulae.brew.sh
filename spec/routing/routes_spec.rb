# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

require 'rails_helper'

describe 'routing' do
  it 'routes / to application#index' do
    expect(get: '/').to route_to('application#index')
  end

  it 'routes /browse/:letter to formulae#browse' do
    expect(get: '/browse/a').to route_to(
      'formulae#browse',
      format: :html,
      letter: 'a'
    )
  end

  it 'routes /browse/:letter/:page to formulae#index' do
    expect(get: '/browse/a/2').to route_to(
      'formulae#browse',
      format: :html,
      letter: 'a',
      page: '2'
    )
  end

  it 'routes /search to formulae#search' do
    expect(get: '/search').to route_to(
      'formulae#search',
      format: :html)
  end

  it 'routes /search/:search to formulae#search' do
    expect(get: '/search/git').to route_to(
      'formulae#search',
      format: :html,
      search: 'git'
    )
  end

  it 'routes /search/:search/:page to formulae#search' do
    expect(get: '/search/git/2').to route_to(
      'formulae#search',
      format: :html,
      search: 'git',
      page: '2'
    )
  end

  it 'routes /formula/:name to formulae#show for name' do
    expect(get: '/formula/git').to route_to(
      'formulae#show',
      format: :html,
      id: 'git'
    )
  end

  it 'routes /formula/:name/version to api#version for name' do
    expect(get: '/formula/git/version').to route_to(
      'api#version',
      format: :json,
      formula_id: 'git'
    )
  end

  it 'routes /feed.atom to formulae#feed' do
    expect(get: '/feed.atom').to route_to('formulae#feed', format: 'atom')
  end

  it 'routes /repos/adamv/homebrew-alt/browse/:letter to formulae#browse' do
    expect(get: '/repos/adamv/homebrew-alt/browse/a').to route_to(
      'formulae#browse',
      format: :html,
      letter: 'a',
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/browse/:letter/:page to formulae#browse' do
    expect(get: '/repos/adamv/homebrew-alt/browse/a/2').to route_to(
      'formulae#browse',
      format: :html,
      letter: 'a',
      page: '2',
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/search to formulae#search' do
    expect(get: '/repos/adamv/homebrew-alt/search').to route_to(
      'formulae#search',
      format: :html,
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/search/:search to formulae#search' do
    expect(get: '/repos/adamv/homebrew-alt/search/git').to route_to(
      'formulae#search',
      format: :html,
      repository_id: 'adamv/homebrew-alt',
      search: 'git'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/search/:search/:page to formulae#search' do
    expect(get: '/repos/adamv/homebrew-alt/search/git/2').to route_to(
      'formulae#search',
      format: :html,
      repository_id: 'adamv/homebrew-alt',
      search: 'git',
      page: '2'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/formula/:name to formulae#show for name' do
    expect(get: '/repos/adamv/homebrew-alt/formula/git').to route_to(
      'formulae#show',
      format: :html,
      id: 'git',
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/formula/:name/version to api#version for name' do
    expect(get: '/repos/adamv/homebrew-alt/formula/git/version').to route_to(
      'api#version',
      format: :json,
      formula_id: 'git',
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /repos/adamv/homebrew-alt/feed.atom to formulae#feed' do
    expect(get: '/repos/adamv/homebrew-alt/feed.atom').to route_to(
      'formulae#feed',
      format: 'atom',
      repository_id: 'adamv/homebrew-alt'
    )
  end

  it 'routes /sitemap.xml to application#sitemap' do
    expect(get: '/sitemap.xml').to route_to('application#sitemap', format: 'xml')
  end

  it 'routes unknown URLs to application#not_found' do
    expect(get: '/unknown').to route_to('application#not_found', url: 'unknown')
  end

  it 'disallows DELETE requests' do
    expect(delete: '/').to route_to('application#forbidden')
    expect(delete: '/formula/git').to route_to('application#forbidden', url: 'formula/git')
    expect(delete: '/repos/adamv/homebrew-alt/formula/git').to route_to('application#forbidden', url: 'repos/adamv/homebrew-alt/formula/git')
  end

  it 'disallows POST requests' do
    expect(post: '/').to route_to('application#forbidden')
    expect(post: '/formula/git').to route_to('application#forbidden', url: 'formula/git')
    expect(post: '/repos/adamv/homebrew-alt/formula/git').to route_to('application#forbidden', url: 'repos/adamv/homebrew-alt/formula/git')
  end

  it 'disallows PUT requests' do
    expect(put: '/').to route_to('application#forbidden')
    expect(put: '/formula/git').to route_to('application#forbidden', url: 'formula/git')
    expect(put: '/repos/adamv/homebrew-alt/formula/git').to route_to('application#forbidden', url: 'repos/adamv/homebrew-alt/formula/git')
  end

end
