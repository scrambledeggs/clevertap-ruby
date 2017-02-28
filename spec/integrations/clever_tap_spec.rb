require 'spec_helper'

RSpec.describe 'Clever Tap integration', vcr: true do
  # NOTE: clear mutations in CleverTap config
  before do
    CleverTap.configure(account_id: AUTH_ACCOUNT_ID, passcode: AUTH_PASSCODE)
  end

  after do
    CleverTap.instance_variable_set('@config', nil)
    CleverTap.instance_variable_set('@client', nil)
  end

  describe 'uploading a profile' do
    context 'when is valid' do
      let(:profile) { Profile.build_valid }

      it 'succeed' do
        response = CleverTap.upload_profile(profile)

        aggregate_failures do
          expect(response.status).to eq('success')
          expect(response.errors).to be_empty
        end
      end
    end

    context 'when is invalid' do
      let(:profile) { Profile.build_valid('Email' => '$$$$$') }

      it 'fail' do
        response = CleverTap.upload_profile(profile)

        aggregate_failures do
          expect(response.status).to eq('fail')
          expect(response.errors.tap { |a, *_| a.delete('error') }).to contain_exactly(
            a_hash_including('status' => 'fail', 'record' => a_hash_including('identity' => profile['id'].to_s))
          )
        end
      end
    end
  end

  describe 'uploading a many profiles' do
    context 'when only some are valid' do
      let(:profiles) { [Profile.build_valid, Profile.new] }

      it 'partial succeed' do
        response = CleverTap.upload_profile(profiles)

        aggregate_failures do
          expect(response.status).to eq('partial')
          expect(response.errors).to contain_exactly(
            a_hash_including(
              'status' => 'fail',
              'record' => a_hash_including('identity' => '', 'profileData' => {})
            )
          )
        end
      end
    end
  end

  describe 'uploading an event' do
    context 'when is valid' do
      let(:event) do
        {
          'user_id' => 555,
          'mobile' => true
        }
      end

      it 'succeed' do
        response = CleverTap.upload_event(event, name: 'register', identity_field: 'user_id')

        aggregate_failures do
          expect(response.status).to eq('success')
          expect(response.errors).to be_empty
        end
      end
    end
  end
end