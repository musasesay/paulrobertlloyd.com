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
            else
              puts "Data folder already exists"
            end

            # Write _data/photosets folder, if doesn’t exist
            if !Dir.exist?(photosets_dir)
              puts "Creating folder to save photoset data in"
              Dir.mkdir(photosets_dir, 0777)
            else
              puts "Photoset data folder already exists"
            end

            # Write photoset data
            path = File.join(photosets_dir, "#{@photoset}.yml")

            if File.exist?(path)
              puts "Reading data for photoset #{@photoset}"
              photos = YAML::load(File.read(path))
            else
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
          id    = photos.photo[i].id
          title = photos.photo[i].title

          # TODO: Get date from flickr.photos.getInfo, not flickr.photos.getExif
          date_created  = exif.find { |e| e.tag == "CreateDate" }

          exif          = flickr.photos.getExif(:photo_id => id).exif.to_a
          model         = exif.find { |e| e.tag == "Model"}
          f_number      = exif.find { |e| e.tag == "FNumber" }
          exposure_time = exif.find { |e| e.tag == "ExposureTime" }
          iso           = exif.find { |e| e.tag == "ISO" }
          focal_length  = exif.find { |e| e.tag == "FocalLength" }

          sizes         = flickr.photos.getSizes(:photo_id => id)
          urlThumb      = sizes.find { |s| s.label == "Large Square" }
          urlEmbeded    = sizes.find { |s| s.label == "Medium 800" }
          urlOpened     = sizes.find { |s| s.label == "Large" }
          urlVideo      = sizes.find { |s| s.label == "Site MP4" }

          # TODO: Don't output YAML key if has no value
          photo = {
            'id' => id,
            'title' => title,
            'date_created' => date_created ? date_created.raw.gsub!(/(\d{4}):(\d{2}):(\d{2}) (\d{2}:\d{2}:\d{2})/, '\\1-\\2-\\3 \\4') : nil,
            'model' => model ? model.raw : nil,
            'f_number' => f_number ? f_number.raw : nil,
            'exposure_time' => exposure_time ? exposure_time.raw : nil,
            'iso' => iso ? iso.raw : nil,
            'focal_length' => focal_length ? focal_length.raw : nil,
            'urlThumb' => urlThumb ? urlThumb.source : nil,
            'urlEmbeded' => urlEmbeded ? urlEmbeded.source : nil,
            'urlOpened' => urlOpened ? urlOpened.source : nil,
            'urlVideo' => urlVideo ? urlVideo.source : nil,
          }

          returnSet.push photo
        end

        returnSet
      end

    end
  end
end
