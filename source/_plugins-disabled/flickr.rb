# Flickr Photoset Tag
#
# A Jekyll plug-in for embedding Flickr photoset in your Liquid templates.
#
# Usage:
#
#   {% flickr_photoset 72157624158475427 %}
#   {% flickr_photoset 72157624158475427 "Square" "Medium 640" "Large" "Site MP4" %}
#
# For futher information please visit: https://github.com/j0k3r/jekyll-flickr-photoset
#
# Author: Jeremy Benoist
# Source: https://github.com/j0k3r/jekyll-flickr-photoset

require 'flickraw'
require 'shellwords'

# FlickRaw.api_key="... Your API key ..."
# FlickRaw.shared_secret="... Your shared secret ..."
#
# token = flickr.get_request_token
# auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
#
# puts "Open this url in your process to complete the authication process : #{auth_url}"
# puts "Copy here the number given when you complete the process."
# verify = gets.strip
#
# begin
#   flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
#   login = flickr.test.login
#   puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
# rescue FlickRaw::FailedResponse => e
#   puts "Authentication failed : #{e.msg}"
# end

module Jekyll

  class FlickrPhotosetTag < Liquid::Tag
    include Jekyll::LiquidExtensions

    def initialize(tag_name, markup, tokens)
      super
      params    = Shellwords.split(markup)
      @photoset = params[0]
    end

    def render(context)
      # Convert a variable (for example `page.gallery_id`) into Flickr set ID
      if @photoset =~ /([\w]+\.[\w]+)/i
        @photoset = lookup_variable(context, @photoset)
      end

      flickrConfig = context.registers[:site].config["flickr"]

      if cache_dir = flickrConfig['cache_dir']
        if !Dir.exist?(cache_dir)
          Dir.mkdir(cache_dir, 0777)
        end

        path = File.join(cache_dir, "#{@photoset}.yml")
        #if File.exist?(path)
        # photos = YAML::load(File.read(path))
        #else
          photos = generate_photo_data(@photoset, flickrConfig)
          File.open(path, 'w') { |f| f.print(YAML::dump(photos)) }
        #end
      else
        photos = generate_photo_data(@photoset, flickrConfig)
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

        exif = flickr.photos.getExif(:photo_id => id).exif.to_a

        date_created  = exif.find { |e| e.tag == "CreateDate" }
        model         = exif.find { |e| e.tag == "Model"}
        f_number      = exif.find { |e| e.tag == "FNumber" }
        exposure_time = exif.find { |e| e.tag == "ExposureTime" }
        iso           = exif.find { |e| e.tag == "ISO" }
        focal_length  = exif.find { |e| e.tag == "FocalLength" }

        urlThumb   = String.new
        urlEmbeded = String.new
        urlOpened  = String.new
        urlVideo   = String.new

        sizes = flickr.photos.getSizes(:photo_id => id)

        urlThumb   = sizes.find { |s| s.label == "Large Square" }
        urlEmbeded = sizes.find { |s| s.label == "Medium 800" }
        urlOpened  = sizes.find { |s| s.label == "Large" }
        urlVideo   = sizes.find { |s| s.label == "Site MP4" }

        photo = {
          'id' => id,
          'title' => title,
          'date_created' => date_created ? date_created.raw : '',
          'model' => model ? model.raw : '',
          'f_number' => f_number ? f_number.raw : '',
          'exposure_time' => exposure_time ? exposure_time.raw : '',
          'iso' => iso ? iso.raw : '',
          'focal_length' => focal_length ? focal_length.raw : '',
          'urlThumb' => urlThumb ? urlThumb.source : '',
          'urlEmbeded' => urlEmbeded ? urlEmbeded.source : '',
          'urlOpened' => urlOpened ? urlOpened.source : '',
          'urlVideo' => urlVideo ? urlVideo.source : '',
          'urlFlickr' => urlVideo ? urlVideo.url : '',
        }

        returnSet.push photo
      end

      # Sleep a little to not get in trouble for bombarding Flickr servers
      sleep 1

      returnSet
    end
  end

end

Liquid::Template.register_tag('flickr_photoset', Jekyll::FlickrPhotosetTag)
