module Products
  module Imports
    class Csv
      require 'csv'

      def initialize(attachment, import)
        @attachment = attachment
        @import     = import
        @success    = 0
        @failure    = 0
      end

      def call
        CSV.foreach(file_path, col_sep: (";"), headers: true) do |row|
          row = row.to_h.compact.deep_symbolize_keys
          params = make_valid_params(row)
          price  = row[:price]

          begin
            if (row.keys & required_fields).count >= required_fields.count
              if products_slug.include?(params[:slug])
                product_update(params)
              else
                product_create(price, params)
              end
              @success += 1
            else
              @failure += 1
            end
          rescue ActiveRecord::StatementInvalid => e
            @failure += 1
          end
        end

        save_import_details
      rescue => error
        import.error!
      end

      private

      attr_reader :attachment, :import

      def product_create(price, params)
        return unless price

        ActiveRecord::Base.connection.exec_query <<~SQL
          WITH products AS (
              INSERT INTO spree_products (#{params.keys.join ', '})
              SELECT #{params.values.map{|e| spree_product_collection.connection.quote(e)}.join ', '}
              WHERE NOT EXISTS (
                SELECT (#{params.keys.join ', '}) FROM spree_products WHERE name='#{params[:name]}'
              )
              RETURNING id AS product_id
          ), variants AS (
            INSERT INTO spree_variants (product_id, is_master , position, created_at, updated_at)
            SELECT product_id, 'true', 1, '#{Time.zone.now}', '#{Time.zone.now}'
            FROM products
            RETURNING id as variant_id
          ), prices AS (
            INSERT INTO spree_prices (variant_id, amount, currency)
            SELECT variant_id, '#{price.gsub(",", ".")}', 'USD'
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
            name = '#{params[:name]}',
            description = '#{params[:description]}',
            updated_at = '#{Time.zone.now}'
          WHERE slug = '#{params[:name]}'
        SQL
      end

      def products_slug
        @products_slug ||= spree_product_collection.pluck(:slug)
      end

      def required_fields
        [:name, :price]
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

      def save_import_details
        data = {
          total_count: File.new(attachment.file.path).readlines.size - 1,
          success_count: @success,
          failure_count: @failure
        }

        import.data = data
        import.save!
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
