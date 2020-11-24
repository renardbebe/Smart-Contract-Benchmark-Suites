 

 

contract mortal {
	address owner;

	function mortal() {
		owner = msg.sender;
	}

	function kill() {
		if (owner == msg.sender)
			suicide(owner);
	}
}

contract Display is mortal {
	 
	uint[][] prices;
	 
	uint16[] duration;
	 
	Ad[] ads;
	 
	uint[] locks;

	struct Ad {
		 
		uint32 id;
		 
		uint8 adType;
		 
		uint expiry;
		 
		address client;
	}

	 
	function Display() {
		prices = [
			[100000000000000000, 300000000000000000, 500000000000000000],
			[500000000000000000, 1500000000000000000, 2500000000000000000],
			[2000000000000000000, 5000000000000000000, 8000000000000000000]
		];
		duration = [1, 7, 30];
		locks = [now, now, now];
	}

	 
	function() payable {
		buyAd(0, 0);
	}

	 
	function buyAd(uint8 adType, uint8 interval) payable {
		if (adType >= prices.length || interval >= duration.length || msg.value < prices[interval][adType]) throw;
		if (locks[adType] > now) throw;
		ads.push(Ad(uint32(ads.length), adType, now + msg.value / prices[interval][adType] * duration[interval] * 1 days, msg.sender));
	}

	 
	function changePrices(uint[3] newPrices, uint8 interval) {
		prices[interval] = newPrices;
	}

	 
	function withdraw() {
		if (msg.sender == owner)
			owner.send(address(this).balance);
	}

	 
	function get10Ads(uint startIndex) constant returns(uint32[10] ids, uint8[10] adTypes, uint[10] expiries, address[10] clients) {
		uint endIndex = startIndex + 10;
		if (endIndex > ads.length) endIndex = ads.length;
		uint j = 0;
		for (uint i = startIndex; i < endIndex; i++) {
			ids[j] = ads[i].id;
			adTypes[j] = (ads[i].adType);
			expiries[j] = (ads[i].expiry);
			clients[j] = (ads[i].client);
			j++;
		}
	}

	 
	function getNumAds() constant returns(uint) {
		return ads.length;
	}

	 
	function getPricesPerInterval(uint8 interval) constant returns(uint[]) {
		return prices[interval];
	}

	 
	function getPrice(uint8 adType, uint8 interval) constant returns(uint) {
		return prices[interval][adType];
	}

	 
	function lock(uint8 adType, uint expiry) {
		locks[adType] = expiry;
	}
}