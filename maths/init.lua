require [[random]]

MT_RAND_GENERATOR = random.new(os.time())

-- Generate a better random value
function mt_rand()
  return math.floor(MT_RAND_GENERATOR() * mt_getrandmax())
end

-- Show largest possible random value
function mt_getrandmax()
  -- return 2*2*2*2*2*
         -- 2*2*2*2*2*
         -- 2*2*2*2*2*
         -- 2*2*2*2*2*
         -- 2*2*2*2*2*
         -- 2*2*2*2*2*
         -- 2 - 1
  return 2147483647 -- Same as the PHP hardcoded one in ext/standard/php_rand.h
end
