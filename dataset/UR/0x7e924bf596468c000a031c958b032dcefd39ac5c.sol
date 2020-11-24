 

pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract LockedSecretChallenge is Ownable  {
	using SafeMath for uint256;

	
	 	
	Peculium public pecul;  
	uint256 decimals;
	bool public initPecul;  
	event InitializedToken(address contractToken);

	uint256 startdate;
	uint256 degeldate;


	address[10] challengeAddress;
	uint256[10] challengeAmount;
	bool public initChallenge;
	event InitializedChallengeAddress(address[10] challengeA, uint256[10] challengeT);
	
	 
	constructor() {
		startdate = now;
		degeldate = 1551890520;  
		}
	
	
	 
	
	function InitPeculiumAdress(address peculAdress) public onlyOwner 
	{  
	
		pecul = Peculium(peculAdress);
		decimals = pecul.decimals();
		initPecul = true;
		emit InitializedToken(peculAdress);
	
	}
	
	function InitChallengeAddress(address[] addressC) public onlyOwner Initialize {
	
		for(uint256 i=0; i<challengeAddress.length;i++){
			challengeAddress[i] = addressC[i];
			challengeAmount[i] = 1000000;
		}
		emit InitializedChallengeAddress(challengeAddress,challengeAmount);
	}
		
	function transferFinal() public onlyOwner Initialize InitializeChallengeAddress
	{  
		
		require(now >= degeldate);
		require ( challengeAddress.length == challengeAmount.length );
		
		for(uint256 i=0; i<challengeAddress.length;i++){
			require(challengeAddress[i]!=0x0);
		}
		uint256 amountToSendTotal = 0;
		
		for (uint256 indexTest=0; indexTest<challengeAmount.length; indexTest++)  
		{
		
			amountToSendTotal = amountToSendTotal + challengeAmount[indexTest]; 
		
		}
		require(amountToSendTotal*10**decimals<=pecul.balanceOf(this));  
		
		
		for (uint256 index=0; index<challengeAddress.length; index++) 
		{
			address toAddress = challengeAddress[index];
			uint256 amountTo_Send = challengeAmount[index]*10**decimals;
		
	                pecul.transfer(toAddress,amountTo_Send);
		}

				
	}
	
	function emergency() public onlyOwner 
	{  
		pecul.transfer(owner,pecul.balanceOf(this));
	}
	
		 
	modifier InitializeChallengeAddress {  
		require (initChallenge==true);
		_;
    	}

	
	modifier Initialize {  
		require (initPecul==true);
		_;
    	}

}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool)  {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract Peculium is BurnableToken,Ownable {  

	 	
	PeculiumOld public peculOld;  
	address public peculOldAdress = 0x53148Bb4551707edF51a1e8d7A93698d18931225;  

	using SafeMath for uint256;  
	using SafeERC20 for ERC20Basic; 

    	 
	string public name = "Peculium";  
    	string public symbol = "PCL";  
    	uint256 public decimals = 8;  
    	
    	 
        uint256 public constant MAX_SUPPLY_NBTOKEN   = 20000000000*10**8;  

	mapping(address => bool) public balancesCannotSell;  


    	 
	event ChangedTokens(address changedTarget,uint256 amountToChanged);
	event FrozenFunds(address address_target, bool bool_canSell);

   
	 
	function Peculium() public {
		totalSupply = MAX_SUPPLY_NBTOKEN;
		balances[address(this)] = totalSupply;  
		peculOld = PeculiumOld(peculOldAdress);	
	}
	
	 	
				
	function transfer(address _to, uint256 _value) public returns (bool) 
	{  
	
		require(balancesCannotSell[msg.sender]==false);
		return BasicToken.transfer(_to,_value);
	
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
	{  
	
		require(balancesCannotSell[msg.sender]==false);	
		return StandardToken.transferFrom(_from,_to,_value);
	
	}

	 	

   	function ChangeLicense(address target, bool canSell) public onlyOwner
   	{
        
        	balancesCannotSell[target] = canSell;
        	FrozenFunds(target, canSell);
    	
    	}
    	
    		function UpgradeTokens() public
	{
	 
	 
		require(peculOld.totalSupply()>0);
		uint256 amountChanged = peculOld.allowance(msg.sender,address(this));
		require(amountChanged>0);
		peculOld.transferFrom(msg.sender,address(this),amountChanged);
		peculOld.burn(amountChanged);

		balances[address(this)] = balances[address(this)].sub(amountChanged);
    		balances[msg.sender] = balances[msg.sender].add(amountChanged);
		Transfer(address(this), msg.sender, amountChanged);
		ChangedTokens(msg.sender,amountChanged);
		
	}

	 	
	
	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);

		require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        	return true;
    }

  	function getBlockTimestamp() public constant returns (uint256)
  	{
        	return now;
  	}

  	function getOwnerInfos() public constant returns (address ownerAddr, uint256 ownerBalance)  
  	{  
    	
    		ownerAddr = owner;
		ownerBalance = balanceOf(ownerAddr);
  	
  	}

}

contract PeculiumOld is BurnableToken,Ownable {  

	using SafeMath for uint256;  
	using SafeERC20 for ERC20Basic; 

    	 
	string public name = "Peculium";  
    	string public symbol = "PCL";  
    	uint256 public decimals = 8;  
    	
    	 
        uint256 public constant MAX_SUPPLY_NBTOKEN   = 20000000000*10**8;  

	uint256 public dateStartContract;  
	mapping(address => bool) public balancesCanSell;  
	uint256 public dateDefrost;  


    	 
 	event FrozenFunds(address target, bool frozen);     	 
     	event Defroze(address msgAdd, bool freeze);
	


   
	 
	function PeculiumOld() {
		totalSupply = MAX_SUPPLY_NBTOKEN;
		balances[owner] = totalSupply;  
		balancesCanSell[owner] = true;  
		
		dateStartContract=now;
		dateDefrost = dateStartContract + 85 days;  

	}

	 	
	
	function defrostToken() public 
	{  
	
		require(now>dateDefrost);
		balancesCanSell[msg.sender]=true;
		Defroze(msg.sender,true);
	}
				
	function transfer(address _to, uint256 _value) public returns (bool) 
	{  
	
		require(balancesCanSell[msg.sender]);
		return BasicToken.transfer(_to,_value);
	
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
	{  
	
		require(balancesCanSell[msg.sender]);	
		return StandardToken.transferFrom(_from,_to,_value);
	
	}

	 	

   	function freezeAccount(address target, bool canSell) onlyOwner 
   	{
        
        	balancesCanSell[target] = canSell;
        	FrozenFunds(target, canSell);
    	
    	}


	 	
	
	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);

		require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        	return true;
    }

  	function getBlockTimestamp() constant returns (uint256)
  	{
        
        	return now;
  	
  	}

  	function getOwnerInfos() constant returns (address ownerAddr, uint256 ownerBalance)  
  	{  
    	
    		ownerAddr = owner;
		ownerBalance = balanceOf(ownerAddr);
  	
  	}

}