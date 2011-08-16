module I18n

  module Backend
    class Simple
      def available_locales
        init_translations unless initialized?
        translations.keys
      end
    end
  end

  class << self
    def available_locales
      backend.available_locales
    end

    def fallback(exception, locale, key, options)
      if (MissingTranslationData === exception) && (locale != self.default_locale)
        begin
          return translate(key, options.merge(:locale => self.default_locale, :raise => true))
        rescue MissingTranslationData
        end
      end

      send :default_exception_handler, exception, locale, key, options
    end
  end

end

I18n.default_locale = AppConfig.locale.default
I18n.exception_handler = :fallback
