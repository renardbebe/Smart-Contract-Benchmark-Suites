 

pragma solidity ^0.4.19;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
  	if (a == 0) {
  		return 0;
  	}
  	uint256 c = a * b;
  	assert(c / a == b);
  	return c;
  }

   
  
 
   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  	assert(b <= a);
  	return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a + b;
  	assert(c >= a);
  	return c;
  }
}


contract CityMayor {

	using SafeMath for uint256;

	 
	 
	 

   	string public name = "CityCoin";
   	string public symbol = "CITY";
   	uint8 public decimals = 0;

	mapping(address => uint256) balances;

	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	uint256 totalSupply_;
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	mapping (address => mapping (address => uint256)) internal allowed;


	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
			} else {
				allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
			}
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

   	 
   	 
   	 

   	address public unitedNations;  

   	uint16 public MAX_CITIES = 5000;  
   	uint256 public UNITED_NATIONS_FUND = 5000000;  
   	uint256 public ECONOMY_BOOST = 5000;  

   	uint256 public BUY_CITY_FEE = 3;  
   	uint256 public ECONOMY_BOOST_TRADE = 100;  

   	uint256 public MONUMENT_UN_FEE = 3;  
   	uint256 public MONUMENT_CITY_FEE = 3;  

   	 
   	 
   	 

   	struct country {
   		string name;
   		uint16[] cities;
   	}

   	struct city {
   		string name;
   		uint256 price;
   		address owner;

   		uint16 countryId;
   		uint256[] monuments;

   		bool buyable;  

   		uint256 last_purchase_price;
   	}

   	struct monument {
   		string name;
   		uint256 price;
   		address owner;

   		uint16 cityId;
   	}

   	city[] public cities;  
   	country[] public countries;  
   	monument[] public monuments;  

   	 
	uint256 public totalOffer;

   	 
   	 
   	 


	event NewCity(uint256 cityId, string name, uint256 price, uint16 countryId);
	event NewMonument(uint256 monumentId, string name, uint256 price, uint16 cityId);

	event CityForSale(uint16 cityId, uint256 price);
	event CitySold(uint16 cityId, uint256 price, address previousOwner, address newOwner, uint256 offerId);

	event MonumentSold(uint256 monumentId, uint256 price);

   	 
   	 
   	 

   	 
   	function CityMayor() public {
   		unitedNations = msg.sender;
   		balances[unitedNations] = UNITED_NATIONS_FUND;  
   		uint256 perFounder = 500000;
   		balances[address(0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b)] = perFounder;  
   		balances[address(0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4)] = perFounder;  
   		balances[address(0xD5d6301dE62D82F461dC29824FC597D38d80c424)] = perFounder;  
   		 
   		totalSupply_ = UNITED_NATIONS_FUND + 3 * perFounder;
   	}

   	 
   	function AdminBuyForSomeone(uint16 _cityId, address _owner) public {
   		 
   		require(msg.sender == unitedNations);
	   	 
	   	city memory fetchedCity = cities[_cityId];
	   	 
		require(fetchedCity.buyable == true);
		require(fetchedCity.owner == 0x0); 
	   	 
	   	cities[_cityId].owner = _owner;
	   	 
	   	cities[_cityId].buyable = false;
	   	cities[_cityId].last_purchase_price = fetchedCity.price;
	   	 
	   	uint16[] memory fetchedCities = countries[fetchedCity.countryId].cities;
	   	uint256 perCityBoost = ECONOMY_BOOST / fetchedCities.length;
	   	for(uint16 ii = 0; ii < fetchedCities.length; ii++){
	   		address _to = cities[fetchedCities[ii]].owner;
	   		if(_to != 0x0) {  
	   			balances[_to] = balances[_to].add(perCityBoost);
	   			totalSupply_ += perCityBoost;  
	   		}
	   	}
	   	 
	   	CitySold(_cityId, fetchedCity.price, 0x0, _owner, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);	
   	}

   	 
	function makeOfferForCityForSomeone(uint16 _cityId, uint256 _price, address from) public payable {
		 
		require(msg.sender == unitedNations);
		 
		require(cities[_cityId].owner != 0x0);
		require(_price > 0);
		require(msg.value >= _price);
		require(cities[_cityId].owner != from);
		 
		uint256 lastId = offers.push(offer(_cityId, _price, from)) - 1;
		 
		totalOffer = totalOffer.add(_price);
		 
		OfferForCity(lastId, _cityId, _price, from, cities[_cityId].owner);
	}

	 
	function adminWithdraw(uint256 _amount) public {
		require(msg.sender == 0xD5d6301dE62D82F461dC29824FC597D38d80c424 || msg.sender == 0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4 || msg.sender == 0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b || msg.sender == unitedNations);
		 
		uint256 totalAvailable = this.balance.sub(totalOffer);
		if(_amount > totalAvailable) {
			_amount = totalAvailable;
		}
		 
		uint256 perFounder = _amount / 3;
		address(0xD5d6301dE62D82F461dC29824FC597D38d80c424).transfer(perFounder);  
		address(0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4).transfer(perFounder);  
		address(0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b).transfer(perFounder);  
	}

	 
	 
	 

	 
	function adminAddCountry(string _name) public returns (uint256) {
		 
		require(msg.sender == unitedNations);
		 
		uint256 lastId = countries.push(country(_name, new uint16[](0))) - 1; 
		 
		return lastId;
	}
	 
	function adminAddCity(string _name, uint256 _price, uint16 _countryId) public returns (uint256) {
		 
		require(msg.sender == unitedNations);
		require(cities.length < MAX_CITIES);
		 
		uint256 lastId = cities.push(city(_name, _price, 0, _countryId, new uint256[](0), true, 0)) - 1;
		countries[_countryId].cities.push(uint16(lastId));
		 
		NewCity(lastId, _name, _price, _countryId);
		 
		return lastId;
	}

	 
	function adminAddMonument(string _name, uint256 _price, uint16 _cityId) public returns (uint256) {
		 
		require(msg.sender == unitedNations);
		require(_price > 0);
		 
		uint256 lastId = monuments.push(monument(_name, _price, 0, _cityId)) - 1;
		cities[_cityId].monuments.push(lastId);
		 
		NewMonument(lastId, _name, _price, _cityId);
		 
		return lastId;
	}

	 
	function adminEditCity(uint16 _cityId, string _name, uint256 _price, address _owner) public {
		 
		require(msg.sender == unitedNations);
		require(cities[_cityId].owner == 0x0);
		 
		cities[_cityId].name = _name;
		cities[_cityId].price = _price;
		cities[_cityId].owner = _owner;
	}

	 
	 
	 

	function buyCity(uint16 _cityId) public payable {
		 
		city memory fetchedCity = cities[_cityId];
		 
		require(fetchedCity.buyable == true);
		require(fetchedCity.owner == 0x0); 
		require(msg.value >= fetchedCity.price);
		 
		cities[_cityId].owner = msg.sender;
		 
		cities[_cityId].buyable = false;
		cities[_cityId].last_purchase_price = fetchedCity.price;
		 
		uint16[] memory fetchedCities = countries[fetchedCity.countryId].cities;
		uint256 perCityBoost = ECONOMY_BOOST / fetchedCities.length;
		for(uint16 ii = 0; ii < fetchedCities.length; ii++){
			address _to = cities[fetchedCities[ii]].owner;
			if(_to != 0x0) {  
				balances[_to] = balances[_to].add(perCityBoost);
				totalSupply_ += perCityBoost;  
			}
		}
		 
		CitySold(_cityId, fetchedCity.price, 0x0, msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
	}

	 
	 
	 
	 
	 

	function economyBoost(uint16 _countryId, uint16 _excludeCityId) private {
		if(balances[unitedNations] < ECONOMY_BOOST_TRADE) {
			return;  
		}
		uint16[] memory fetchedCities = countries[_countryId].cities;
		if(fetchedCities.length == 1) {
			return;
		}
		uint256 perCityBoost = ECONOMY_BOOST_TRADE / (fetchedCities.length - 1);  
		for(uint16 ii = 0; ii < fetchedCities.length; ii++){
			address _to = cities[fetchedCities[ii]].owner;
			if(_to != 0x0 && fetchedCities[ii] != _excludeCityId) {  
				balances[_to] = balances[_to].add(perCityBoost);
				balances[unitedNations] -= perCityBoost;
			}
		}
	}

	 
	 
	 

	 
	function sellCityForEther(uint16 _cityId, uint256 _price) public {
		 
		require(cities[_cityId].owner == msg.sender);
		 
		cities[_cityId].price = _price;
		cities[_cityId].buyable = true;
		 
		CityForSale(_cityId, _price);
	}

	event CityNotForSale(uint16 cityId);

	 
	function cancelSellCityForEther(uint16 _cityId) public {
		 
		require(cities[_cityId].owner == msg.sender);
		 
		cities[_cityId].buyable = false;
		 
		CityNotForSale(_cityId);
	}

	 
	function resolveSellCityForEther(uint16 _cityId) public payable {
		 
		city memory fetchedCity = cities[_cityId];
		 
		require(fetchedCity.buyable == true);
		require(msg.value >= fetchedCity.price);
		require(fetchedCity.owner != msg.sender);
		 
		uint256 fee = BUY_CITY_FEE.mul(fetchedCity.price) / 100;
		 
		address previousOwner =	fetchedCity.owner;
		previousOwner.transfer(fetchedCity.price.sub(fee));
		 
		cities[_cityId].owner = msg.sender;
		 
		cities[_cityId].buyable = false;
		cities[_cityId].last_purchase_price = fetchedCity.price;
		 
		economyBoost(fetchedCity.countryId, _cityId);
		 
		CitySold(_cityId, fetchedCity.price, previousOwner, msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
	}

	 
	 
	 

	struct offer {
		uint16 cityId;
		uint256 price;
		address from;
	}

	offer[] public offers;

	event OfferForCity(uint256 offerId, uint16 cityId, uint256 price, address offererAddress, address owner);
	event CancelOfferForCity(uint256 offerId);

	 
	function makeOfferForCity(uint16 _cityId, uint256 _price) public payable {
		 
		require(cities[_cityId].owner != 0x0);
		require(_price > 0);
		require(msg.value >= _price);
		require(cities[_cityId].owner != msg.sender);
		 
		uint256 lastId = offers.push(offer(_cityId, _price, msg.sender)) - 1;
		 
		totalOffer = totalOffer.add(_price);
		 
		OfferForCity(lastId, _cityId, _price, msg.sender, cities[_cityId].owner);
	}

	 
	function cancelOfferForCity(uint256 _offerId) public {
		 
		offer memory offerFetched = offers[_offerId];
		 
		require(offerFetched.from == msg.sender);
		 
		msg.sender.transfer(offerFetched.price);
		 
		totalOffer = totalOffer.sub(offerFetched.price);
		 
		offers[_offerId].cityId = 0;
		offers[_offerId].price = 0;
		offers[_offerId].from = 0x0;
		 
		CancelOfferForCity(_offerId);
	}

	 
	function acceptOfferForCity(uint256 _offerId, uint16 _cityId, uint256 _price) public {
		 
		city memory fetchedCity = cities[_cityId];
		offer memory offerFetched = offers[_offerId];
		 
		require(offerFetched.cityId == _cityId);
		require(offerFetched.from != 0x0);
		require(offerFetched.from != msg.sender);
		require(offerFetched.price == _price);
		require(fetchedCity.owner == msg.sender);
		 
		uint256 fee = BUY_CITY_FEE.mul(_price) / 100;
		 
		uint256 priceSubFee = _price.sub(fee);
		cities[_cityId].owner.transfer(priceSubFee);
		 
		totalOffer = totalOffer.sub(priceSubFee);
		 
		cities[_cityId].owner = offerFetched.from;
		 
		cities[_cityId].last_purchase_price = _price;
		cities[_cityId].buyable = false;  
		 
		economyBoost(fetchedCity.countryId, _cityId);
		 
		CitySold(_cityId, _price, msg.sender, offerFetched.from, _offerId);
		 
		offers[_offerId].cityId = 0;
		offers[_offerId].price = 0;
		offers[_offerId].from = 0x0;
	}

	 
	 
	 

	 

	 
	function buyMonument(uint256 _monumentId, uint256 _price) public {
		 
		monument memory fetchedMonument = monuments[_monumentId];
		 
		require(fetchedMonument.price > 0);
		require(fetchedMonument.price == _price);
		require(balances[msg.sender] >= _price);
		require(fetchedMonument.owner != msg.sender);
		 
		balances[msg.sender] = balances[msg.sender].sub(_price);
		 
		uint256 UN_fee = MONUMENT_UN_FEE.mul(_price) / 100;
		uint256 city_fee = MONUMENT_CITY_FEE.mul(_price) / 100;
		 
		uint256 toBePaid = _price.sub(UN_fee);
		toBePaid = toBePaid.sub(city_fee);
		balances[fetchedMonument.owner] = balances[fetchedMonument.owner].add(toBePaid);
		 
		balances[unitedNations] = balances[unitedNations].add(UN_fee);
		 
		address cityOwner = cities[fetchedMonument.cityId].owner;
		balances[cityOwner] = balances[cityOwner].add(city_fee);
		 
		monuments[_monumentId].owner = msg.sender;
		 
		monuments[_monumentId].price = monuments[_monumentId].price.mul(2);
		 
		MonumentSold(_monumentId, _price);
	}

}