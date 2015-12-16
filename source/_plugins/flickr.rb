# TODO: Fix needing to run twice: once to write data, then again to read it
# TODO: Add means of only displaying certain images from set (using tags?)
# TODO: Add initial auth setup for FlickRaw
# TODO: Allow list of photosets to be generated to be listed in site config

require 'flickraw'

module Jekyll
  module Flickr
    class Flickr < Jekyll::Generator

      DEFAULTS = {
        'folder_name' => 'photosets'
      }


      def initialize(config = nil)
        if config['jekyll-flickr'].nil?
          @config = DEFAULTS
        else
          @config = Utils.deep_merge_hashes(DEFAULTS, config['jekyll-flickr'])
        end
      end


      def generate(site)
        @site = site
        @site.config['jekyll-flickr'] = @config

        data_dir = site.config['source'] + '/_data'
        folder_name = @config['folder_name']
        photosets_dir = data_dir + '/' + folder_name

        Jekyll::Hooks.register :documents, :pre_render do |document|
          if document.data['photoset']
            @photoset = document.data['photoset']

            # Write _data folder, if doesn’t exist
            if !Dir.exist?(data_dir)
              puts "Creating folder to save site data in"
              Dir.mkdir(data_dir, 0777)
            end

            # Write _data/photosets folder, if doesn’t exist
            if !Dir.exist?(photosets_dir)
              puts "Creating folder to save photoset data in"
              Dir.mkdir(photosets_dir, 0777)
            end

            # Write photoset data, if doesn't exist
            path = File.join(photosets_dir, "#{@photoset}.yml")

            if !File.exist?(path)
              puts "Writing data for photoset #{@photoset}"
              photos = generate_photo_data(@photoset, @config)
              File.open(path, 'w') { |f| f.print(YAML::dump(photos)) }
            end
          end
        end

      end


      def generate_photo_data(photoset, flickrConfig)
        returnSet = Array.new

        FlickRaw.api_key       = ENV['FLICKR_API_KEY'] || flickrConfig['api_key']
        FlickRaw.shared_secret = ENV['FLICKR_SHARED_SECRET'] || flickrConfig['shared_secret']
        flickr.access_token    = ENV['FLICKR_ACCESS_TOKEN'] || flickrConfig['access_token']
        flickr.access_secret   = ENV['FLICKR_ACCESS_SECRET'] || flickrConfig['access_secret']

        begin
          flickr.test.login
        rescue Exception => e
          raise "Unable to login, please check documentation for correctly configuring Environment Variables, or _config.yaml."
        end

        begin
          photos = flickr.photosets.getPhotos :photoset_id => photoset
        rescue Exception => e
          raise "Bad photoset: #{photoset}"
        end

        photos.photo.each_index do | i |
          id            = photos.photo[i].id

          info          = flickr.photos.getInfo(:photo_id => id)
          title         = info.title
          date          = info.dates.taken
          media         = info.media

          exif          = flickr.photos.getExif(:photo_id => id).exif.to_a
          model         = exif.find { |e| e.tag == "Model"}
          f_number      = exif.find { |e| e.tag == "FNumber" }
          exposure_time = exif.find { |e| e.tag == "ExposureTime" }
          iso           = exif.find { |e| e.tag == "ISO" }
          focal_length  = exif.find { |e| e.tag == "FocalLength" }

          sources       = flickr.photos.getSizes(:photo_id => id)
          small         = sources.find { |s| s.label == "Medium" }
          medium        = sources.find { |s| s.label == "Medium 800" }
          large         = sources.find { |s| s.label == "Large" }
          original      = sources.find { |s| s.label == "Original" }
          video         = sources.find { |s| s.label == "Site MP4" }

          if media == 'photo'
            photo = {
              'title' => title,
              'date' => date ? date : nil,
              'model' => model ? model.raw : nil,
              'f_number' => f_number ? f_number.raw : nil,
              'exposure_time' => exposure_time ? exposure_time.raw : nil,
              'iso' => iso ? iso.raw : nil,
              'focal_length' => focal_length ? focal_length.raw : nil,
              'src' => {
                'small' => small ? small.source : nil,
                'medium' => medium ? medium.source : nil,
                'large' => large ? large.source : nil,
                'original' => original ? original.source : nil
              }
            }
          else
            photo = {
              'title' => title,
              'date' => date ? date : nil,
              'src' => {
                'poster' => medium ? medium.source : nil,
                'video' => video ? video.source : nil
              }
            }
          end

          returnSet.push photo
        end

        returnSet
      end

    end
  end
end
