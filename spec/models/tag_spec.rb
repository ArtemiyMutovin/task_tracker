require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tasks).through(:task_tags) }
  end

  describe 'validations' do
    subject { build(:tag) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'name normalization' do
    it 'downcases and strips the name before validation' do
      tag = build(:tag, name: '  Тест  ')
      tag.valid?
      expect(tag.name).to eq('тест')
    end

    it 'prevents creation of mixed-case duplicates' do
      create(:tag, name: 'звонок')
      duplicate = build(:tag, name: 'ЗВОНОК')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'system tag protection' do
    let!(:system_tag)  { create(:tag, :system, name: 'отчетность') }
    let!(:regular_tag) { create(:tag) }

    it 'cannot be updated' do
      expect(system_tag.update(name: 'new name')).to be(false)
      expect(system_tag.reload.name).to eq('отчетность')
    end

    it 'cannot be destroyed' do
      expect { system_tag.destroy }.not_to change(Tag, :count)
    end

    it 'allows updating regular tags' do
      expect(regular_tag.update(name: 'updated')).to be(true)
    end

    it 'allows destroying regular tags' do
      expect { regular_tag.destroy }.to change(Tag, :count).by(-1)
    end
  end
end
