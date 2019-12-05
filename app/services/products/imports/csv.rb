module Products
  module Imports
    class Csv
      require 'csv'

      def initialize(attachment, import)
        @attachment = attachment
        @import     = import
      end

      def call
        CSV.foreach(file_path, col_sep: (","), headers: true) do |row|
          row = row.to_h.compact.deep_symbolize_keys
          params = make_valid_params(row)
          price  = row.to_h['price']

          begin
            if (row.keys & required_fields).count >= required_fields.count
              if products_slug.include?(params[:slug])
                product_update(params)
              else
                product_create(price, params)
              end
            end
          rescue ActiveRecord::StatementInvalid => e
            # raise some error
          end
        end
      end

      private

      attr_reader :attachment, :import

      def product_create(price, params)
        return unless price

        ActiveRecord::Base.connection.exec_query <<~SQL
          WITH products AS (
            INSERT INTO spree_products (#{params.keys.join ', '})
            VALUES (#{params.values.map{|e| spree_product_collection.connection.quote(e)}.join ', '})
            RETURNING id as product_id
          ), variants AS (
            INSERT INTO spree_variants (product_id, is_master , position, created_at, updated_at)
            SELECT product_id, 'true', 1, '#{Time.zone.now}', '#{Time.zone.now}'
            FROM products
            RETURNING id as variant_id
          ), prices AS (
            INSERT INTO spree_prices (variant_id, amount, currency)
            SELECT variant_id, #{price}, 'USD'
            FROM variants
          )

          INSERT INTO spree_stock_items (variant_id, stock_location_id, backorderable, created_at, updated_at)
          SELECT variant_id, 1, 'true', '#{Time.zone.now}', '#{Time.zone.now}'
          FROM variants
        SQL
      end

      def product_update(params)
        ActiveRecord::Base.connection.exec_query <<~SQL
          UPDATE spree_products SET
            name = '#{params[:name]}', description = '#{params[:description]}', updated_at = '#{Time.zone.now}'
          WHERE slug = '#{params[:slug]}'
        SQL
      end

      def products_slug
        spree_product_collection.pluck(:slug)
      end

      def required_fields
        [:name, :slug, :price]
      end

      def make_valid_params(row)
        return {} if row.nil?

        {
          name:                 row[:name].presence,
          description:          row[:description].presence,
          slug:                 row[:slug].presence,
          shipping_category_id: shipping_category.id,
          created_at:           Time.zone.now,
          updated_at:           Time.zone.now
        }.compact
      end

      def file_path
        @file_path ||= attachment.file.path
      end

      def shipping_category
        @shippting_category ||= shipping_category_collection.find_or_create_by!(name: 'Default')
      end

      def shipping_category_collection
        Spree::ShippingCategory
      end

      def spree_product_collection
        Spree::Product
      end
    end
  end
end
