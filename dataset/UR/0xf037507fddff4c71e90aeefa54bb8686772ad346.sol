 

 

pragma solidity ^0.4.25; 

contract EtherGarden{

	mapping (uint8 => uint256) public VegetablesTradeBalance;
	mapping (address => uint8) public FarmerToFieldId;
 	mapping (address => mapping (uint8 => uint256)) public FarmerVegetableStartGrowing;
 	mapping (address => mapping (uint8 => uint256)) public FarmerVegetableFieldSize;

	uint256 MaxVegetables = 4;
	uint256 minimumInvest = 0.001 ether;
	uint256 growingSpeed = 1 days; 
	bool public initialized=false;
	address public admin;
	
     
    constructor() public {
        admin = msg.sender;
    }
	
     	
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier isInitialized() {
        require(initialized);
        _;
    }	

     		
    function() external payable {
		 


		if (msg.value >= 0 && msg.value <= 0.00001 ether) {
			if (FarmerToFieldId[msg.sender] == 0) {
				rollFieldId();
				getFreeField();
			} else
				sellVegetables();
        } 
		else if (msg.value == 0.00001111 ether){
			reInvest();
        } 
		else {
			if (FarmerToFieldId[msg.sender] == 0)
				rollFieldId();		
            buyField();
        }		
    }	 

    function sellVegetables() internal isInitialized {
		uint8 _VegetableId = FarmerToFieldId[msg.sender];
		
		uint256 value = vegetablesValue(_VegetableId, msg.sender);
        if (value > 0) {
			uint256 price = SafeMath.mul(vegetablePrice(_VegetableId),value);
			uint256 fee = devFee(price);
			
			FarmerVegetableStartGrowing[msg.sender][_VegetableId] = now;
			
			 
			VegetablesTradeBalance[_VegetableId] = SafeMath.add(VegetablesTradeBalance[_VegetableId],value);
			
			admin.transfer(fee);
			msg.sender.transfer(SafeMath.sub(price,fee));
		}
    }	 
	
    function buyField() internal isInitialized {
		require(msg.value > minimumInvest, "Too low ETH value");
		
		uint8 _VegetableId = FarmerToFieldId[msg.sender];
		
		 
		uint256 acres = SafeMath.div(msg.value,fieldPrice(msg.value));
        
		if (FarmerVegetableStartGrowing[msg.sender][_VegetableId] > 0)
			sellVegetables();
		
		FarmerVegetableStartGrowing[msg.sender][_VegetableId] = now;
		FarmerVegetableFieldSize[msg.sender][_VegetableId] = SafeMath.add(FarmerVegetableFieldSize[msg.sender][_VegetableId],acres);
		
		 
		VegetablesTradeBalance[_VegetableId] = SafeMath.add(VegetablesTradeBalance[_VegetableId], SafeMath.div(acres,5));
		
        uint256 fee = devFee(msg.value);
		admin.send(fee);
		
        if (msg.data.length == 20) {
            address _referrer = bytesToAddress(bytes(msg.data));
			if (_referrer != msg.sender && _referrer != address(0)) {
				 _referrer.send(fee);
			}
        }		
    }
	 
	function reInvest() internal isInitialized {
		uint8 _VegetableId = FarmerToFieldId[msg.sender];
		
		uint256 value = vegetablesValue(_VegetableId, msg.sender);
		require(value > 0, "No grown vegetables for reinvest");
		
		 
		FarmerVegetableFieldSize[msg.sender][_VegetableId] = SafeMath.add(FarmerVegetableFieldSize[msg.sender][_VegetableId],value);
		FarmerVegetableStartGrowing[msg.sender][_VegetableId] = now;
	}
	
    function getFreeField() internal isInitialized {
		uint8 _VegetableId = FarmerToFieldId[msg.sender];
		require(FarmerVegetableFieldSize[msg.sender][_VegetableId] == 0);
		
		FarmerVegetableFieldSize[msg.sender][_VegetableId] = freeFieldSize();
		FarmerVegetableStartGrowing[msg.sender][_VegetableId] = now;
		
    }
	
    function initMarket(uint256 _init_value) public payable onlyAdmin{
        require(!initialized);
        initialized=true;
		
		 
		for (uint8 _vegetableId = 0; _vegetableId < MaxVegetables; _vegetableId++)
			VegetablesTradeBalance[_vegetableId] = _init_value;
    }	
	
	function rollFieldId() internal {
	     
		FarmerToFieldId[msg.sender] = uint8(uint256(blockhash(block.number - 1)) % MaxVegetables + 1);
	}
	
     		

	function bytesToAddress(bytes _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }	
	
     		
	 
    function vegetablePrice(uint8 _VegetableId) public view returns(uint256){
		return SafeMath.div(SafeMath.div(address(this).balance,MaxVegetables),VegetablesTradeBalance[_VegetableId]);
    }

    function vegetablesValue(uint8 _VegetableId, address _Farmer) public view returns(uint256){
		 
		return SafeMath.div(SafeMath.mul(FarmerVegetableFieldSize[_Farmer][_VegetableId], SafeMath.sub(now,FarmerVegetableStartGrowing[_Farmer][_VegetableId])),growingSpeed);		
    }	
	
    function fieldPrice(uint256 subValue) public view returns(uint256){
	    uint256 CommonTradeBalance;
		
		for (uint8 _vegetableId = 0; _vegetableId < MaxVegetables; _vegetableId++)
			CommonTradeBalance=SafeMath.add(CommonTradeBalance,VegetablesTradeBalance[_vegetableId]);
		
		return SafeMath.div(SafeMath.sub(address(this).balance,subValue), CommonTradeBalance);
    }
	
	function freeFieldSize() public view returns(uint256) {
		return SafeMath.div(0.0005 ether,fieldPrice(0));
	}
	
	function devFee(uint256 _amount) internal pure returns(uint256){
        return SafeMath.div(SafeMath.mul(_amount,4),100);
    }
	
}

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