module Spree
  module StructuredDataHelper
    def products_structured_data(products)
      content_tag :script, type: 'application/ld+json' do
        raw(
          products.map do |product|
            structured_product_hash(product)
          end.to_json
        )
      end
    end

    private

    def structured_product_hash(product)
      Rails.cache.fetch(common_product_cache_keys + ["spree/structured-data/#{product.cache_key_with_version}"]) do
        {
          '@context': 'https://schema.org/',
          '@type': 'Product',
          '@id': "#{spree.root_url}product_#{product.id}",
          url: spree.product_url(product),
          name: product.name,
          image: structured_images(product),
          description: product.description,
          sku: structured_sku(product),
          google_product_category: structured_google_product_category(product),
          offers: {
            '@type': 'Offer',
            price: product.default_variant.price_in(current_currency).amount,
            priceCurrency: current_currency,
            availability: product.in_stock? ? 'InStock' : 'OutOfStock',
            url: spree.product_url(product),
            availabilityEnds: product.discontinue_on ? product.discontinue_on.strftime('%F') : ''
          }
        }.compact
      end
    end

    def structured_sku(product)
      product.default_variant.sku? ? product.default_variant.sku : product.sku
    end

    def structured_images(product)
      image = default_image_for_product_or_variant(product)

      return '' unless image

      main_app.rails_blob_url(image.attachment)
    end

    def structured_google_product_category(product)
      product.product_properties.find_by(property: product.properties.find_by(name: 'google_product_category'))&.value
    end
  end
end
