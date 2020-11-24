 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract SeekerCoin is ERC20,Ownable{
	using SafeMath for uint256;

	 
	string public constant name="Seeker Coin";
	string public constant symbol="SEC";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public rate;
	uint256 public totalFundingSupply;
	 
	uint256 public MAX_SUPPLY;

	 
	mapping(address=>epoch[]) public lockEpochsMap;

    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	struct epoch  {
        uint256 endTime;
        uint256 amount;
    }

	function SeekerCoin(){
		MAX_SUPPLY = 10000000000*10**decimals;
		rate = 0;
		totalFundingSupply = 0;
		totalSupply = 0;
	}

	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	function lockBalance(address user, uint256 amount,uint256 endTime) external
		onlyOwner
	{
		 epoch[] storage epochs = lockEpochsMap[user];
		 epochs.push(epoch(endTime,amount));
	}
	
	function () payable external
	{
			processFunding(msg.sender,msg.value,rate);
			uint256 amount=msg.value.mul(rate);
			totalFundingSupply = totalFundingSupply.add(amount);
	}

	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
		notReachTotalSupply(_value,_rate)
	{
		uint256 amount=_value.mul(_rate);
		totalSupply=totalSupply.add(amount);
		balances[receiver] +=amount;
		Transfer(0x0, receiver, amount);
	}

    function withdrawCoinToOwner(uint256 _value) external
		onlyOwner
	{
		processFunding(msg.sender,_value,1);
	}
	
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}



	function setRate(uint256 _rate) external
		onlyOwner
	{
		rate=_rate;
	}

  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));
		epoch[] epochs = lockEpochsMap[msg.sender];
		uint256 needLockBalance = 0;
		for(uint256 i;i<epochs.length;i++)
		{
			if( now < epochs[i].endTime )
			{
				needLockBalance=needLockBalance.add(epochs[i].amount);
			}
		}

		require(balances[msg.sender].sub(_value)>=needLockBalance);
		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}


  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));

		epoch[] epochs = lockEpochsMap[_from];
		uint256 needLockBalance = 0;
		for(uint256 i;i<epochs.length;i++)
		{
			if( now < epochs[i].endTime )
			{
				needLockBalance = needLockBalance.add(epochs[i].amount);
			}
		}

		require(balances[_from].sub(_value)>=needLockBalance);
		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}

	  
}

contract TAKD is ERC20,Ownable{
	using SafeMath for uint256;

	 
	string public constant name="America TransAKT Company Limited";
	string public constant symbol="TAKD";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_SUPPLY=1000000000*10**decimals;

    struct epoch  {
        uint256 endTime;
        uint256 amount;
    }

	mapping(address=>epoch[]) public lockEpochsMap;


	 
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

	function TAKD(){
		totalSupply = MAX_SUPPLY;
		balances[msg.sender] = MAX_SUPPLY;
		Transfer(0x0, msg.sender, MAX_SUPPLY);
	}

	function () payable external
	{
	}

	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}

	function lockBalance(address user, uint256 amount,uint256 endTime) external
		onlyOwner
	{
		 epoch[] storage epochs = lockEpochsMap[user];
		 epochs.push(epoch(endTime,amount));
	}




  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));
		epoch[] epochs = lockEpochsMap[msg.sender];
		uint256 needLockBalance = 0;
		for(uint256 i;i<epochs.length;i++)
		{
			if( now < epochs[i].endTime )
			{
				needLockBalance=needLockBalance.add(epochs[i].amount);
			}
		}

		require(balances[msg.sender].sub(_value)>=needLockBalance);
		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}


  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));

		epoch[] epochs = lockEpochsMap[_from];
		uint256 needLockBalance = 0;
		for(uint256 i;i<epochs.length;i++)
		{
			if( now < epochs[i].endTime )
			{
				needLockBalance = needLockBalance.add(epochs[i].amount);
			}
		}

		require(balances[_from].sub(_value)>=needLockBalance);
		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}

	  
}