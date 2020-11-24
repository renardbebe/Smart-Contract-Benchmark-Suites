 

pragma solidity ^0.4.20;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
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

contract Ownable {

  address public coOwner;

  function Ownable() public {
    coOwner = msg.sender;
  }

  modifier onlyCoOwner() {
    require(msg.sender == coOwner);
    _;
  }

  function transferCoOwnership(address _newOwner) public onlyCoOwner {
    require(_newOwner != address(0));

    coOwner = _newOwner;

    CoOwnershipTransferred(coOwner, _newOwner);
  }
  
  function CoWithdraw() public onlyCoOwner {
      coOwner.transfer(this.balance);
  }  
  
  event CoOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}

contract CryptoCarsRent is ERC721, Ownable {

  event CarCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "CryptoCars";
  string public constant SYMBOL = "CarsToken";

  uint256 private startingSellPrice = 0.012 ether;

  mapping (uint256 => address) public carIdToOwner;

  mapping (uint256 => address) public carIdToRenter;
  mapping (uint256 => uint256) public carIdRentStartTime;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public carIdToApproved;

  mapping (uint256 => uint256) private carIdToPrice;
  mapping (uint256 => uint256) private carIdToProfit;

   
  struct Car {
    string name;
  }

  Car[] private cars;

  function approve(address _to, uint256 _tokenId) public {  
     
    require(_owns(msg.sender, _tokenId));
    carIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {  
    return ownershipTokenCount[_owner];
  }

  function createCarToken(string _name) public onlyCoOwner {
    _createCar(_name, address(this), startingSellPrice);
  }

  function createCarsTokens() public onlyCoOwner {

	for (uint8 car=0; car<21; car++) {
	   _createCar("Crypto Car", address(this), startingSellPrice);
	 }

  }
  
  function getCar(uint256 _tokenId) public view returns (string carName, uint256 sellingPrice, address owner) {
    Car storage car = cars[_tokenId];
    carName = car.name;
    sellingPrice = carIdToPrice[_tokenId];
    owner = carIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) {  
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) {  
    owner = carIdToOwner[_tokenId];
    require(owner != address(0));
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = carIdToOwner[_tokenId];
    address newOwner = msg.sender;
	uint256 renter_payment;
	uint256 payment;
	
	if (now - carIdRentStartTime[_tokenId] > 7200)  
		carIdToRenter[_tokenId] = address(0);
		
	address renter = carIdToRenter[_tokenId];

    uint256 sellingPrice = carIdToPrice[_tokenId];
	uint256 profit = carIdToProfit[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);
	
	

    if (renter != address(0)) {
		renter_payment = uint256(SafeMath.div(SafeMath.mul(profit, 45), 100));  
		payment = uint256(SafeMath.sub(SafeMath.div(SafeMath.mul(sellingPrice, 97), 100), renter_payment));  
	} else {
		renter_payment = 0;
		payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));  
	}

	
     
	if (sellingPrice < 500 finney) {
		carIdToPrice[_tokenId] = SafeMath.mul(sellingPrice, 2);  
	}
	else {
		carIdToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 15), 10));  
	}
	
     
  	carIdToProfit[_tokenId] = uint256(SafeMath.sub(carIdToPrice[_tokenId], sellingPrice));
    carIdToRenter[_tokenId] = address(0);
	carIdRentStartTime[_tokenId] =  0;
	
    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

     
    if (renter != address(0)) {
      renter.transfer(renter_payment);  
    }

    TokenSold(_tokenId, sellingPrice, carIdToPrice[_tokenId], oldOwner, newOwner, cars[_tokenId].name);
	
    if (msg.value > sellingPrice) {  
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }

  function rent(uint256 _tokenId) public payable {
	require(now - carIdRentStartTime[_tokenId] > 7200);  
	require(msg.sender != carIdToOwner[_tokenId]);
	
	uint256 profit = carIdToProfit[_tokenId];  
	uint256 rentPrice = uint256(SafeMath.div(SafeMath.mul(profit, 10), 100));  
     
    require(_addressNotNull(msg.sender));
    require(msg.value >= rentPrice);	 
	
	carIdRentStartTime[_tokenId] = now;
	carIdToRenter[_tokenId] = msg.sender;
	
	address carOwner = carIdToOwner[_tokenId];
	require(carOwner != address(this));
	
	
    if (carOwner != address(this)) {
      carOwner.transfer(rentPrice);  
    }
	
    if (msg.value > rentPrice) {  
	    uint256 purchaseExcess = SafeMath.sub(msg.value, rentPrice);
		msg.sender.transfer(purchaseExcess);
	}	
  }
  
  
  function symbol() public pure returns (string) {  
    return SYMBOL;
  }


  function takeOwnership(uint256 _tokenId) public {  
    address newOwner = msg.sender;
    address oldOwner = carIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }
  
  function allCarsInfo() public view returns (address[] owners, address[] renters, uint256[] prices, uint256[] profits) {  
	
	uint256 totalResultCars = totalSupply();
	
    if (totalResultCars == 0) {
         
      return (new address[](0),new address[](0),new uint256[](0),new uint256[](0));
    }
	
	address[] memory owners_res = new address[](totalResultCars);
	address[] memory renters_res = new address[](totalResultCars);
	uint256[] memory prices_res = new uint256[](totalResultCars);
	uint256[] memory profits_res = new uint256[](totalResultCars);
	
	for (uint256 carId = 0; carId < totalResultCars; carId++) {
	  owners_res[carId] = carIdToOwner[carId];
	  if (now - carIdRentStartTime[carId] <= 7200)  
		renters_res[carId] = carIdToRenter[carId];
	  else 
		renters_res[carId] = address(0);
		
	  prices_res[carId] = carIdToPrice[carId];
	  profits_res[carId] = carIdToProfit[carId];
	}
	
	return (owners_res, renters_res, prices_res, profits_res);
  }  

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {  
    return carIdToPrice[_tokenId];
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {  
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCars = totalSupply();
      uint256 resultIndex = 0;

      uint256 carId;
      for (carId = 0; carId <= totalCars; carId++) {
        if (carIdToOwner[carId] == _owner) {
          result[resultIndex] = carId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) {  
    return cars.length;
  }

  function transfer(address _to, uint256 _tokenId) public {  
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

	_transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {  
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }


   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return carIdToApproved[_tokenId] == _to;
  }

  function _createCar(string _name, address _owner, uint256 _price) private {
    Car memory _car = Car({
      name: _name
    });
    uint256 newCarId = cars.push(_car) - 1;

    require(newCarId == uint256(uint32(newCarId)));  

    CarCreated(newCarId, _name, _owner);

    carIdToPrice[newCarId] = _price;

    _transfer(address(0), _owner, newCarId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == carIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    carIdToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete carIdToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
}