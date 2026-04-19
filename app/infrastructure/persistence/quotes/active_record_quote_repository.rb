# frozen_string_literal: true

module Persistence
  module Quotes
    class ActiveRecordQuoteRepository
      include ::Quotes::QuoteRepository

      def find(id)
        record = QuoteRecord.includes(:quote_line_item_records).find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_work_order_id(work_order_id)
        record = QuoteRecord.includes(:quote_line_item_records).find_by(work_order_id: work_order_id)
        return nil unless record

        to_entity(record)
      end

      def save(quote)
        record = persist_quote(quote)
        sync_line_items(record, quote.line_items)

        to_entity(record.reload)
      end

      def all
        QuoteRecord.includes(:quote_line_item_records).map { |record| to_entity(record) }
      end

      def delete(id)
        QuoteRecord.find_by(id: id)&.destroy
      end

      private

      def persist_quote(quote)
        if quote.id
          QuoteRecord.find(quote.id).tap { |r| r.update!(to_attributes(quote)) }
        else
          QuoteRecord.create!(to_attributes(quote))
        end
      end

      def sync_line_items(record, line_items)
        record.quote_line_item_records.where.not(id: line_items.map(&:id).compact).destroy_all

        line_items.each do |item|
          if item.id
            record.quote_line_item_records.find(item.id).update!(line_item_attributes(item))
          else
            record.quote_line_item_records.create!(line_item_attributes(item))
          end
        end
      end

      def to_entity(record)
        ::Quotes::Quote.new(
          id: record.id,
          work_order_id: record.work_order_id,
          line_items: record.quote_line_item_records.map { |line| line_item_to_entity(line) },
          status: record.status.to_sym,
          created_at: record.created_at
        )
      end

      def line_item_to_entity(record)
        ::Quotes::QuoteLineItem.new(
          id: record.id,
          description: record.description,
          quantity: record.quantity,
          unit_price: record.unit_price_cents
        )
      end

      def to_attributes(quote)
        {
          work_order_id: quote.work_order_id,
          status: quote.status.to_s
        }
      end

      def line_item_attributes(line_item)
        {
          description: line_item.description,
          quantity: line_item.quantity,
          unit_price_cents: line_item.unit_price.cents
        }
      end
    end
  end
end
