module Spree
  module Admin
    module Products
      module Csv
        class ImportsController < Spree::Admin::BaseController

          def create
            if attachment.save
              import_service.call

              flash[:notice] = "File successfull uploaded"
              redirect_to admin_products_csv_import_path(import)
            else
              flash[:error] = "Error: #{ attachment.errors.full_messages.first }"

              render :new
            end
          end

          private

          def import_service
            ::Products::Imports::Csv.new(attachment, import)
          end

          def attachment
            @attachment ||= attachment_collection.new(file: permit_params[:csv])
          end

          def import
            @import ||= import_collection.create!(attachment_id: attachment.id)
          end

          def permit_params
            params.permit(:csv)
          end

          def attachment_collection
            Attachment
          end

          def import_collection
            Import
          end
        end
      end
    end
  end
end