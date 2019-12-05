class ProductImportWorker
  include Sidekiq::Worker

  def perform(*args)
    attachment = Attachment.find(args[0]['attachment_id'])
    import     = Import.find(args[0]['import_id'])

    import_service.new(attachment, import).call
  end

  private

  def import_service
    ::Products::Imports::Csv
  end
end
