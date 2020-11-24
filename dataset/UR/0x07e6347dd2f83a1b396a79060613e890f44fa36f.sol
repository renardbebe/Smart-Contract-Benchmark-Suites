 

pragma solidity ^0.4.23;

 
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
     
     
     
    return a / b;
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
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferFromContract(address _to, uint256 _value) internal returns (bool) {
    require(_to != address(0));
    require(_value <= balances[address(this)]);

     
    balances[address(this)] = balances[address(this)].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(address(this), _to, _value);
    return true;
  }  

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) internal {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}


contract MintableToken is BasicToken {
   
  event Mint(address indexed to, uint256 amount);

   
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  
} 

contract EFToken is MintableToken, BurnableToken, Ownable {
  string public constant name = "EtherFactoryToken"; 
  string public constant symbol = "EFT"; 
  uint8 public constant decimals = 0;  
  
  uint256 internal presellStart = now;
  
  mapping(uint256 => address) internal InviterAddress; 
  mapping(address => uint256) public InviterToID; 
 
  uint256 private InviterID = 0;
  
  function sellTokens(uint256 _value) public gameStarted {
  
    require (balances[msg.sender] >= _value && _value > 0);
	uint256 balance = address(this).balance;
	require (balance > 0);
	
    uint256 total = totalSupply();
	uint256 sellRate = uint256( balance.div( total ) );
	uint256 ethValue = sellRate.mul(_value);
	msg.sender.transfer(ethValue);
	burn(_value);
	
  } 
  
  function buyTokens() public gameStarted payable {
    
	uint256 eth = msg.value;
    require ( msg.value>0 );
	uint256 tokensAmount = balances[address(this)];
	uint256 balance = uint256(SafeMath.sub(address(this).balance,msg.value));
	if (balance < 0.1 ether)
		balance = 0.1 ether;
    uint256 total = totalSupply();
	uint256 sellRate = uint256( balance.div( total ) );
	uint256 eftValue = uint256(eth.div(sellRate));
	require ( eftValue <= tokensAmount && eftValue > 0 );
	
	transferFromContract(msg.sender, eftValue);

	uint256 fee = uint256(SafeMath.div(msg.value, 10)); 
	 
	owner.transfer(fee); 	
  } 

  function inviterReg() public {
	require (msg.sender != address(0) && InviterToID[msg.sender] == 0);
	
	InviterID++;
	InviterAddress[InviterID] = msg.sender;
	InviterToID[msg.sender] = InviterID;
  }
  
  function tokensRate() public view returns (uint256 rate, uint256 yourEFT, uint256 totalEFT, uint256 ethBalance, uint256 eftBalance) {
    yourEFT = balanceOf (msg.sender);
    totalEFT = totalSupply();
	ethBalance = address(this).balance;
	rate = uint256(ethBalance.div(totalEFT));
	eftBalance = balances[address(this)];
  }
  
   
  function presellTimer() public view returns (uint256 presellLeft) {
	presellLeft = uint256(SafeMath.div(now.sub(presellStart), 60));
  }
  
   
  modifier gameStarted() {
    require(now - presellStart >= 604800);  
    _;
  }
    
}

contract EtherFactory is EFToken {

   
  mapping(uint256 => mapping(uint8 => uint256)) internal FactoryPersonal; 
  
   
  mapping(uint256 => address) internal FactoryOwner; 
  
   
  mapping(uint256 => uint256) internal FactoryWorkStart; 
  
   
  mapping(uint256 => uint8) internal FactoryLevel; 
  
    
  mapping(uint256 => uint256) internal FactoryPrice; 

    
  mapping(uint256 => string) internal FactoryName; 
  
   
  mapping(address => uint8) internal WorkerQualification; 
  
   
  mapping(address => uint256) internal WorkerFactory; 
  
   
  mapping(address => uint256) internal WorkerWorkStart;   
  
  uint256 FactoryID = 0;
  
   
  
  function setFactoryName(uint256 _FactoryID, string _Name) public {
	require (FactoryOwner[_FactoryID] == msg.sender);	
	require(bytes(_Name).length <= 50);
	FactoryName[_FactoryID] = _Name; 
  }
  
  function getFactoryProfit(uint256 _FactoryID, address _FactoryOwner) public gameStarted {
	require (FactoryOwner[_FactoryID] == _FactoryOwner);
	
	 
	uint256 profitMinutes = uint256(SafeMath.div(SafeMath.sub(now, FactoryWorkStart[_FactoryID]), 60));
	if (profitMinutes > 0) {
		uint256 profit = 0;
		
		for (uint8 level=1; level<=FactoryLevel[_FactoryID]; level++) {
		   profit += SafeMath.mul(SafeMath.mul(uint256(level),profitMinutes), FactoryPersonal[_FactoryID][level]);
		}
		
		if (profit > 0) {
			mint(_FactoryOwner,profit);
			FactoryWorkStart[_FactoryID] = now;
		}
	}
	
  }

  function buildFactory(uint8 _level, uint256 _inviterID) public payable {
  
    require (_level>0 && _level<=100);
	
    uint256 buildCost = uint256(_level).mul( getFactoryPrice() );
	require (msg.value == buildCost);
	
	FactoryID++;
	FactoryOwner[FactoryID] = msg.sender;
	FactoryLevel[FactoryID] = _level;
	FactoryPrice[FactoryID] = SafeMath.mul(0.15 ether, _level);
	
	 
	mint(address(this), SafeMath.mul(1000000, _level));
	
	
	address Inviter = InviterAddress[_inviterID];

	uint256 fee = uint256(SafeMath.div(msg.value, 20)); 
	
	if ( Inviter != address(0)) {
		 
		Inviter.transfer(fee); 
	} else {
	     
		fee = fee.mul(2);
	}
	
	 
	owner.transfer(fee); 	
  }  
  
  function upgradeFactory(uint256 _FactoryID) public payable {
  
    require (FactoryOwner[_FactoryID] == msg.sender);
	require (FactoryLevel[_FactoryID] < 100);
	
	require (msg.value == getFactoryPrice() );

	FactoryLevel[_FactoryID]++ ;
	FactoryPrice[FactoryID] += 0.15 ether;
	
	 
	mint(address(this), 1000000);
	
	uint256 fee = uint256(SafeMath.div(msg.value, 10)); 
	 
	owner.transfer(fee); 
	
  }    
  
  function buyExistFactory(uint256 _FactoryID) public payable {
  
    address factoryOwner = FactoryOwner[_FactoryID];
	
    require ( factoryOwner != address(0) && factoryOwner != msg.sender && msg.sender != address(0) );

    uint256 factoryPrice = FactoryPrice[_FactoryID];
    require(msg.value >= factoryPrice);
	
	 
	FactoryOwner[_FactoryID] = msg.sender;
	
	 
	uint256 Payment90percent = uint256(SafeMath.div(SafeMath.mul(factoryPrice, 9), 10)); 

	 
	uint256 fee = uint256(SafeMath.div(SafeMath.mul(factoryPrice, 5), 100)); 
	
	 
	FactoryPrice[_FactoryID] = uint256(SafeMath.div(SafeMath.mul(factoryPrice, 3), 2)); 

	
    factoryOwner.transfer(Payment90percent); 
	owner.transfer(fee); 
	
	 
    if (msg.value > factoryPrice) { 
		msg.sender.transfer(msg.value - factoryPrice);
	}
  }   
  
  function increaseMarketValue(uint256 _FactoryID, uint256 _tokens) public gameStarted {
  
	uint256 eftTOethRATE = 200000000000;
	
	require (FactoryOwner[_FactoryID] == msg.sender);
	require (balances[msg.sender] >= _tokens && _tokens>0);
	
	FactoryPrice[_FactoryID] = FactoryPrice[_FactoryID] + _tokens*eftTOethRATE;
	burn(_tokens);
  }
  
  
  
   
  
  function findJob(uint256 _FactoryID) public gameStarted {
    
    require (WorkerFactory[msg.sender] != _FactoryID);
  
	if (WorkerQualification[msg.sender] == 0) {
		WorkerQualification[msg.sender] = 1;
	}

	uint8 qualification = WorkerQualification[msg.sender];
		
	require (FactoryLevel[_FactoryID] >= qualification);
	
	 
	require (FactoryPersonal[_FactoryID][qualification] < 100);
	
	 
	if (WorkerFactory[msg.sender]>0) {
		getFactoryProfit(_FactoryID, FactoryOwner[_FactoryID]);
		getWorkerProfit();
	} else {
		WorkerWorkStart[msg.sender] = now;
	}
	
	 
	if (WorkerFactory[msg.sender] > 0 ) {
	   FactoryPersonal[WorkerFactory[msg.sender]][qualification]--;
	}
	
	WorkerFactory[msg.sender] = _FactoryID;
	
	FactoryPersonal[_FactoryID][qualification]++;
	
	if (FactoryWorkStart[_FactoryID] ==0)
		FactoryWorkStart[_FactoryID] = now;
	
  } 
  
  function getWorkerProfit() public gameStarted {
	require (WorkerFactory[msg.sender] > 0);
	
	 
	uint256 profitMinutes = uint256(SafeMath.div(SafeMath.sub(now, WorkerWorkStart[msg.sender]), 60));
	if (profitMinutes > 0) {
		uint8 qualification = WorkerQualification[msg.sender];
		
		uint256 profitEFT = SafeMath.mul(uint256(qualification),profitMinutes);
		
		require (profitEFT > 0);
		
		mint(msg.sender,profitEFT);
		
		WorkerWorkStart[msg.sender] = now;
	}
	
  }  
  
  function upgradeQualificationByTokens() public gameStarted {
	
	require (WorkerQualification[msg.sender]<100);
	
    uint256 upgradeCost = 10000;
	require (balances[msg.sender] >= upgradeCost);
	
	if (WorkerFactory[msg.sender] > 0)
		getWorkerProfit();
    
	uint8 oldQualification = WorkerQualification[msg.sender];
	
	uint256 WorkerFactoryID = WorkerFactory[msg.sender];

	if (WorkerQualification[msg.sender]==0) 
		WorkerQualification[msg.sender]=2;
	else 
		WorkerQualification[msg.sender]++;
	
	if (WorkerFactoryID > 0) {
		getFactoryProfit(WorkerFactoryID, FactoryOwner[WorkerFactoryID]);
		FactoryPersonal[WorkerFactoryID][oldQualification]--;
	
		if (FactoryLevel[WorkerFactoryID] >= oldQualification+1) {
			FactoryPersonal[WorkerFactoryID][oldQualification+1]++;
		} else {
			 
			WorkerFactory[msg.sender] = 0;
		}
	}
	
	 
	burn(upgradeCost);
	
  }   
  
  function upgradeQualificationByEther(uint256 _inviterID) public payable {
	
	require (WorkerQualification[msg.sender]<100);
	
	 
	require ( msg.value == SafeMath.div(getFactoryPrice(),100) );
	
	uint256 fee = uint256(SafeMath.div(msg.value, 20));  
	
	address Inviter = InviterAddress[_inviterID];

	if ( Inviter != address(0)) {
		 
		Inviter.transfer(fee); 
	} else {
	     
		fee = fee.mul(2);
	}
	
	 
	owner.transfer(fee); 
	
	if (WorkerFactory[msg.sender] > 0)
		getWorkerProfit();
    
	uint8 oldQualification = WorkerQualification[msg.sender];
	
	uint256 WorkerFactoryID = WorkerFactory[msg.sender];
	
	if (WorkerQualification[msg.sender]==0) 
		WorkerQualification[msg.sender]=2;
	else 
		WorkerQualification[msg.sender]++;
	
	
	
	if (WorkerFactoryID > 0) {
		getFactoryProfit(WorkerFactoryID, FactoryOwner[WorkerFactoryID]);
		FactoryPersonal[WorkerFactoryID][oldQualification]--;
	
		if (FactoryLevel[WorkerFactoryID] >= oldQualification+1) {
			FactoryPersonal[WorkerFactoryID][oldQualification+1]++;
		} else {
			 
			WorkerFactory[msg.sender] = 0;
		}
	}
	
	
  }  
  
  function getFactoryPrice() internal view returns (uint256 price) {
	if (now - presellStart >= 604800)
		price = 0.1 ether;
	else 
		price = 0.075 ether;
  }
  
  
   

  function allFactories() public constant returns(address[] owner, uint256[] profitMinutes, uint256[] price, uint8[] level) {    

     
	price = new uint256[](FactoryID);
	profitMinutes = new uint256[](FactoryID);
	owner = new address[](FactoryID);
	level = new uint8[](FactoryID);

	for (uint256 index=1; index<=FactoryID; index++) {
		price[index-1] = FactoryPrice[index];
		profitMinutes[index-1] = uint256(SafeMath.div(now - FactoryWorkStart[index],60));
		owner[index-1] = FactoryOwner[index];
		level[index-1] = FactoryLevel[index];
	}
	
  }
  
  function aboutFactoryWorkers(uint256 _FactoryID)  public constant returns(uint256[] workers, string factoryName) {    
	uint8 factoryLevel = FactoryLevel[_FactoryID];
	factoryName = FactoryName[_FactoryID];
	
	workers = new uint256[](factoryLevel+1);
	for (uint8 qualification=1; qualification<=factoryLevel; qualification++)
		workers[qualification] = FactoryPersonal[_FactoryID][qualification];
	
  }  
  
  function aboutWorker(address _worker) public constant returns(uint8 qualification, uint256 factoryId, uint256 profitMinutes, uint8 factoryLevel) {    
	qualification = WorkerQualification[_worker];	
	if (qualification==0)
		qualification=1;
	factoryId = WorkerFactory[_worker];	
	factoryLevel = FactoryLevel[factoryId];
	profitMinutes = uint256(SafeMath.div(now - WorkerWorkStart[_worker],60));
  }
  
  function contractBalance() public constant returns(uint256 ethBalance) {    
	ethBalance = address(this).balance;
  }  
  

}