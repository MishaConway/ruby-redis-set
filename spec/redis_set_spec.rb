require 'spec_helper'

describe RedisSet do
	let(:redis) { Redis.new }
	let(:name) { "some_set" }
	let(:set) { described_class.new(name, redis) }

	before do
		redis.flushall
	end

	context "instance methods" do
		describe '#all' do
			subject { set.all }

			it 'should return all the items in the set' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')

				expect(subject).to eq(%w(a b))
			end
		end

		describe '#size' do
			subject { set.size }

			it 'should return the number of items in the set' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')

				expect(subject).to eq(2)
			end
		end

		describe '#clear' do
			subject { set.clear }

			it 'should remove all of the items in the set' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')

				expect(subject).to eq([])
				expect(redis.scard name).to eq(0)
				expect(set.size).to eq(0)
			end
		end

		describe '#include?' do
			it 'should return true for items in the set, but false otherwise' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')

				expect(set.include?('a')).to be true
				expect(set.include?('b')).to be true
				expect(set.include?('c')).to be false
			end
		end

		describe '#add' do
			context 'single adds' do
				it 'should add items to the set' do
					expect(set.size).to eq(0)

					set.add('a')
					set.add('b')
					set.add('c')

					expect(set.size).to eq(3)
					expect(set.all.sort).to eq(%w(a b c))
				end
			end

			context 'multiple adds through multiple arguments' do
				it 'should add items to the set' do
					expect(set.size).to eq(0)

					set.add('a', 'b', 'c')

					expect(set.size).to eq(3)
					expect(set.all.sort).to eq(%w(a b c))
				end
			end

			context 'multiple adds through an array' do
				it 'should add items to the set' do
					expect(set.size).to eq(0)

					set.add(['a', 'b', 'c'])

					expect(set.size).to eq(3)
					expect(set.all.sort).to eq(%w(a b c))
				end
			end

			context 'multiple adds through both arrays and multiple arguments' do
				it 'should add items to the set' do
					expect(set.size).to eq(0)

					set.add(['a', 'b', 'c'], 'd', 'e', ['f', 'g'], 'h')

					expect(set.size).to eq(8)
					expect(set.all.sort).to eq(%w(a b c d e f g h))
				end
			end
		end

		describe '#remove' do
			it 'should remove a single item from a set' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')
				redis.sadd(name, 'c')
				expect(set.size).to eq(3)

				set.remove 'b'

				expect(set.size).to eq(2)
				expect(set.all.sort).to eq(%w(a c))
			end

			it 'should remove multiple items through multiple arguments' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')
				redis.sadd(name, 'c')
				expect(set.size).to eq(3)

				set.remove 'b', 'c'

				expect(set.size).to eq(1)
				expect(set.all).to eq(%w(a))
			end

			it 'should remove multiple items through an array' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')
				redis.sadd(name, 'c')
				expect(set.size).to eq(3)

				set.remove ['b', 'c']

				expect(set.size).to eq(1)
				expect(set.all).to eq(%w(a))
			end

			it 'should remove multiple items through both multiple arguments and arrays' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')
				redis.sadd(name, 'c')
				redis.sadd(name, 'd')
				redis.sadd(name, 'e')
				redis.sadd(name, 'f')
				expect(set.size).to eq(6)

				set.remove ['b', 'c'], 'e'

				expect(set.size).to eq(3)
				expect(set.all.sort).to eq(%w(a d f))
			end
		end

		describe '#pop' do
		  it 'should pop a single item from the set' do
			  redis.sadd(name, 'a')
			  redis.sadd(name, 'b')
			  redis.sadd(name, 'c')

			  popped = set.pop.first
			  expect(%w(a b c)).to include(popped)
			  expect(set.size).to eq(2)
			  expect(set.all.sort).to eq(%w(a b c) - [popped])
		  end
		end

		describe '#pop' do
			it 'should pop multiple items from the set' do
				redis.sadd(name, 'a')
				redis.sadd(name, 'b')
				redis.sadd(name, 'c')

				popped = set.pop(2)
				expect(popped.size).to eq(2)

				expect(%w(a b c)).to include(popped.first)
				expect(%w(a b c)).to include(popped.last)

				expect(set.size).to eq(1)
				expect(set.all.sort).to eq(%w(a b c) - popped)
			end
		end

		describe '#intersection' do
			let(:name2){"#{name}2"}
			let(:name3){"#{name}3"}

			it 'should return the intersection between multiple sets' do
			  redis.sadd(name, 'a')
			  redis.sadd(name, 'b')
			  redis.sadd(name, 'c')
			  redis.sadd(name, 'd')

			  redis.sadd(name2, 'b')
			  redis.sadd(name2, 'c')
			  redis.sadd(name2, 'd')

			  redis.sadd(name3, 'b')
			  redis.sadd(name3, 'c')

				expect(set.intersection(name2, name3).sort).to eq(%w(b c))
			  expect(set.intersection(RedisSet.new(name2), RedisSet.new(name3)).sort).to eq(%w(b c))
			  expect(set.intersection(name2, RedisSet.new(name3)).sort).to eq(%w(b c))
			end
		end
	end
end