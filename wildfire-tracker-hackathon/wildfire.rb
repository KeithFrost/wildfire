require 'sinatra/base'
require 'rugged'
require 'torrent'
require 'yaml'
require 'json'
require 'uri'

require 'pp'

$:.unshift File.dirname __FILE__
require 'bttrack/peer'
require 'bttrack/info_hash'
require 'bttrack/request'

module Wildfire
  class App < Sinatra::Base
    set :config, YAML.load_file('config/config.yml')
    set :repos,  YAML.load_file('config/repos.yml')

    before do
      Dir.chdir settings.config[:app_dir]
    end

    helpers do
      def tracker_request
        Bttrack::Request.new params.merge(remote_ip: request.ip),
                             settings.config[:tracker].merge(torrents_dir: File.readlink(File.join(File.dirname(__FILE__), settings.config[:torrents_dir])))
      end

      def repo_path repo
        File.join settings.config[:repos_dir], repo
      end

      def download_path repo, commit
        File.join settings.config[:downloads_dir], deploy_key(repo, commit)
      end

      def deploy_key repo, commit
        [repo, commit].join settings.config[:deploy_key_delimiter]
      end

      def copy_repo repo, commit
        options = settings.config[:rsync_options].map do |option|
          '--' + option
        end.join("\s")

        [%x[rsync #{options} #{repo_path(repo)}/ #{download_path(repo, commit)}/], $?]
      end

      def initialize_seed torrent_file
        [%x[/usr/bin/transmission-remote -a #{File.join(File.readlink(settings.config[:torrents_dir]), torrent_file)}], $?]
      end

      def update_release_dns_record torrent_file
        tracker_host = URI.parse(settings.config[:tracker][:url]).host
        tracker_torrent_url = 'http://' + [tracker_host, torrent_file].join('/')

        [%x[/root/tools/update_zone.rb -r release -v #{tracker_torrent_url}], $?]
      end
    end

    get '/' do
      @torrent_count = Dir.glob(File.join(File.readlink(settings.config[:torrents_dir]), '*/*/*')).size rescue :unknown
      @scrapes = Bttrack::InfoHash.scrape
      erb :index
    end

    get '/scrape' do
      case
      when request[:info_hash].nil?
        Bttrack::InfoHash.scrape
      else
        tracker_request.info_hash.scrape
      end.bencode
    end

    get '/announce' do
      info_hash = tracker_request.info_hash

      peers = info_hash.peers compact:    tracker_request.compact?,
                              no_peer_id: tracker_request.no_peer_id?,
                              numwant:    tracker_request.numwant

      info_hash.event event:      tracker_request.event,
                      downloaded: tracker_request.downloaded,
                      uploaded:   tracker_request.uploaded,
                      left:       tracker_request.left,
                      peer:       tracker_request.peer

      peers.bencode
    end

    post '/deploy/:repo/:commit' do
      content_type :json

      unless Dir.exist? File.join repo_path(params[:repo]), '.git'
        raise 'invalid git repo: ' + params[:repo]
      end

      repo = Rugged::Repository.new(repo_path(params[:repo]))

      # ensure the git repoistory is in a clean state before
      # taking action on new deploy
      if repo.head_detached?
        repo.checkout 'master', strategy: :force

        if repo.head_detached?
          raise 'unable to force git repo into clean state'
        end
      end

      # normalize and validate the user requested commit
      commit = case params[:commit].downcase
      when 'head'
        repo.head.target
      else
        unless repo.exists?(params[:commit])
          raise 'invalid git commit: ' + params[:commit]
        end

        params[:commit]
      end

      # checkout user requested commit - TODO: add validation here
      repo.checkout commit, strategy: :force

      # copy project to download directory
      copy_output, copy_status = copy_repo params[:repo], commit
      unless copy_status.success?
        raise ['project copy failed:', copy_output].join("\n")
      end

      # initialize and generate torrent
      torrent = Torrent::Generate.new settings.config[:tracker][:url],
                                      deploy_key(params[:repo], commit)
                                      
      Dir.chdir(download_path(params[:repo], commit)) do
        torrent_files = Dir.glob('**/*').reject do |entry|
          entry.start_with?('.') or File.directory?(entry) or File.symlink?(entry)
        end

        torrent.add_files torrent_files
        torrent.build
      end

      torrent_path = File.join File.readlink(settings.config[:torrents_dir]), 
                               [torrent.name, '.torrent'].join

      # save the torrent
      File.open torrent_path, 'w' do |file|
        file.write torrent.encode
      end

      # initialize seeder
      seeder_output, seeder_status = initialize_seed File.basename(torrent_path)
      unless seeder_status.success?
        raise ['seeder initialization failed:', seeder_output].join("\n")        
      end

      # update release dns record
      dns_update_output, dns_update_status = update_release_dns_record File.basename(torrent_path)
      unless dns_update_status.success?
        raise ['release dns record update failed:', dns_update_status].join("\n")
      end

      {repo: params[:repo], commit: params[:commit], status: :generated}.to_json
    end
  end
end