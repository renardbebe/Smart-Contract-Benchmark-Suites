 

 

pragma solidity ^0.4.25; 

contract EtherGarden{

    using SafeMath for uint256;
 
    struct Farmer {
		uint8   vegetableId;
        uint256 startGrowing;
        uint256 fieldSize;
    }

	mapping (uint8 => uint256) public vegetablesTradeBalance;
	mapping (address => Farmer) public farmers;

	uint256 maxVegetableId = 4;
	uint256 minimumInvest = 0.001 ether;
	uint256 growingSpeed = 1 days; 
	
	bool public gameStarted = false;
	bool public initialized = false;
	address public marketing = 0x25e6142178Fc3Afb7533739F5eDDD4a41227576A;
	address public admin;
	
     
    constructor() public {
        admin = msg.sender;
    }
	
     	
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier isInitialized() {
        require(initialized && gameStarted);
        _;
    }	

     		
    function() external payable {
		
		Farmer storage farmer = farmers[msg.sender];

		if (msg.value >= 0 && msg.value <= 0.00001 ether) {
			if (farmer.vegetableId == 0) {
				 
				rollFieldId();
				
				getFreeField();
			} else
				sellVegetables();
        } 
		else if (msg.value == 0.00001111 ether){
			reInvest();
        } 
		else {
			if (farmer.vegetableId == 0) {
				 
				rollFieldId();		
			}
            buyField();
        }		
    }	 

    function sellVegetables() internal isInitialized {
		Farmer storage farmer = farmers[msg.sender];
		
		uint256 value = vegetablesValue(msg.sender);
		if (value > 0) {
			uint256 sellPrice = vegetablePrice(farmer.vegetableId).mul(value);
			
			if (sellPrice > address(this).balance) {
				sellPrice = address(this).balance;
				 
				gameStarted = false;
			}
			
			uint256 fee = devFee(sellPrice);
			
			farmer.startGrowing = now;
			
			 
			vegetablesTradeBalance[farmer.vegetableId] = vegetablesTradeBalance[farmer.vegetableId].add(value);
			
			admin.transfer(fee);
			msg.sender.transfer(sellPrice.sub(fee));
		}
    }	 
	
    function buyField() internal isInitialized {
		require(msg.value >= minimumInvest, "Too low ETH value");

		Farmer storage farmer = farmers[msg.sender];	

		 
		uint256 acres = msg.value.div(fieldPrice(msg.value));
        
		if (farmer.startGrowing > 0)
			sellVegetables();
		
		farmer.startGrowing = now;
		farmer.fieldSize = farmer.fieldSize.add(acres);
		
		 
		vegetablesTradeBalance[farmer.vegetableId] = vegetablesTradeBalance[farmer.vegetableId].add( acres.div(5) );
		
        uint256 fee = devFee(msg.value);
		marketing.send(fee);
		
        if (msg.data.length == 20) {
            address _referrer = bytesToAddress(bytes(msg.data));
			if (_referrer != msg.sender && _referrer != address(0)) {
				 _referrer.send(fee);
			}
        }		
    }
	 
	function reInvest() internal isInitialized {
		
		Farmer storage farmer = farmers[msg.sender];	
		
		uint256 value = vegetablesValue(msg.sender);
		require(value > 0, "No grown vegetables for reinvest");
		
		 
		farmer.fieldSize = farmer.fieldSize.add(value);
		farmer.startGrowing = now;
	}
	
    function getFreeField() internal isInitialized {
		Farmer storage farmer = farmers[msg.sender];
		require(farmer.fieldSize == 0);
		
		farmer.fieldSize = freeFieldSize();
		farmer.startGrowing = now;
		
    }
	
    function initMarket(uint256 _newTradeBalance) public payable onlyAdmin{
        require(!initialized);
        initialized = true;
		gameStarted = true;
		
		 
		for (uint8 _vegetableId = 1; _vegetableId <= maxVegetableId; _vegetableId++)
			vegetablesTradeBalance[_vegetableId] = _newTradeBalance;
    }	
	
	function rollFieldId() internal {
		Farmer storage farmer = farmers[msg.sender];
		
	     
		farmer.vegetableId = uint8(uint256(blockhash(block.number - 1)) % maxVegetableId + 1);
	}
	
     		

	function bytesToAddress(bytes _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }	
	
     		
	 
    function vegetablePrice(uint8 _VegetableId) public view returns(uint256){
		return address(this).balance.div(maxVegetableId).div(vegetablesTradeBalance[_VegetableId]);
    }

    function vegetablesValue(address _Farmer) public view returns(uint256){
		 
		return farmers[_Farmer].fieldSize.mul( now.sub(farmers[_Farmer].startGrowing) ).div(growingSpeed);
    }	
	
    function fieldPrice(uint256 _subValue) public view returns(uint256){
	    uint256 CommonTradeBalance;
		
		for (uint8 _vegetableId = 1; _vegetableId <= maxVegetableId; _vegetableId++)
			CommonTradeBalance = CommonTradeBalance.add(vegetablesTradeBalance[_vegetableId]);
			
		 
		return ( address(this).balance.sub(_subValue) ).div(CommonTradeBalance);
    }
	
	function freeFieldSize() public view returns(uint256) {
		return minimumInvest.div(fieldPrice(0));
	}
	
	function devFee(uint256 _amount) internal pure returns(uint256){
        return _amount.mul(4).div(100);  
    }
	
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}