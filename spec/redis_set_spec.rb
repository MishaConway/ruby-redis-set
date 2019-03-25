require 'spec_helper'

describe RedisSet do
	let(:redis){Redis.new}
	let(:name){"some_set"}
	let(:set){described_class.new(name, redis)}

	before do
		redis.flushall
	end

	context "instance methods" do
		describe '#all' do
			subject{ set.all }

			it 'should return all the items in the hash' do
				redis.sadd(name, 'a')
				redis.hset(name, 'b')

				expect(subject).to eq(%w(a b))
			end
		end
	end
end