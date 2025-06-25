# Patch for Fixnum/Bignum removal in Ruby 2.4+
# This allows older gems (like annotate) to work on modern Ruby
if Rails.env.development?
  Fixnum = Integer unless defined?(Fixnum)
  Bignum = Integer unless defined?(Bignum)
end
