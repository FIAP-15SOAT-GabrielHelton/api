# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/shared/repository"

RSpec.describe Shared::Repository do
  let(:repo_class) do
    Class.new do
      include Shared::Repository
    end
  end

  let(:repo) { repo_class.new }

  %i[find save delete].each do |method_name|
    describe "##{method_name}" do
      it "raises NotImplementedError when not implemented" do
        expect { repo.public_send(method_name, "arg") }
          .to raise_error(NotImplementedError, /not implemented/)
      end
    end
  end

  describe "#all" do
    it "raises NotImplementedError when not implemented" do
      expect { repo.all }
        .to raise_error(NotImplementedError, /not implemented/)
    end
  end
end
