module Spree
  module Admin
    module Products
      module Csv
        class ImportsController < Spree::Admin::BaseController
          def show
            @import = Import.find(params[:id])
          end

          def create
            if attachment.save
              ::ProductImportWorker.perform_async(
                attachment_id: attachment.id,
                import_id: import.id
              )

              flash[:notice] = "File successfully uploaded. Please wait for import products"
              redirect_to admin_products_csv_import_path(import)
            else
              flash[:error] = "Error: #{ attachment.errors.full_messages.first }"

              render :new
            end
          end

          private

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