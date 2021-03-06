describe Travis::Api::App::Endpoint::Repos, set_app: true do
  include Support::S3

  context 'correctly capture params' do
    before do
      described_class.get('/spec/match/:id')   { "id"   }
      described_class.get('/spec/match/:name') { "name" }
    end

    it 'matches :id with digits' do
      get('/repos/spec/match/123').body.should be == "id"
    end

    it 'does not match :id with non-digits' do
      get('/repos/spec/match/f123').body.should be == "name"
    end
  end

  context 'caches endpoints' do
    let(:user) { Factory.create(:user) }
    let(:repo) { Factory.create(:repository, private: false, owner_name: 'user', name: 'repo') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:cache_options) {{ s3: { bucket_name: '' , access_key_id: '', secret_access_key: ''} }}

    before { Travis.config.cache_options = cache_options }

    context 'with authorized users' do
      before { user.permissions.create(repository_id: repo.id, push: true) }

      it 'responds with 200' do
        get("/repos/#{repo.id}/caches", cache_options, headers).status.should == 200
        delete("/repos/#{repo.id}/caches", cache_options, headers).status.should == 200
        get("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status.should == 200
        delete("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status.should == 200
      end
    end

    context 'with unauthorized users' do
      before { user.permissions.create(repository_id: repo.id, push: false) }

      it 'responds with 403' do
        get("/repos/#{repo.id}/caches", cache_options, headers).status.should == 403
        delete("/repos/#{repo.id}/caches", cache_options, headers).status.should == 403
        get("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status.should == 403
        delete("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status.should == 403
      end
    end
  end
end
