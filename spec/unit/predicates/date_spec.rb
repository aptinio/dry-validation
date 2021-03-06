require 'dry/validation/predicates'

RSpec.describe Dry::Validation::Predicates do
  describe '#date?' do
    let(:predicate_name) { :date? }

    context 'when value is a date' do
      let(:arguments_list) do
        [[Date.today]]
      end

      it_behaves_like 'a passing predicate'
    end

    context 'with value is not an integer' do
      let(:arguments_list) do
        [
          [''],
          [[]],
          [{}],
          [nil],
          [:symbol],
          [String],
          [1]
        ]
      end

      it_behaves_like 'a failing predicate'
    end
  end
end
