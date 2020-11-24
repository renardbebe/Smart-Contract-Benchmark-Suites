 

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract BTMC is ERC20,Ownable,Pausable{
	using SafeMath for uint256;

	 
	string public constant name="MinerCoin";
	string public constant symbol="BTMC";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	 
	uint256 public constant INIT_SUPPLY=100000000*10**decimals;

	 
	uint256 public constant MINING_SUPPLY=500000000*10**decimals;


	 
	uint256 public constant MAX_FUNDING_SUPPLY=200000000*10**decimals;

	 
	uint256 public constant TEAM_KEEPING=200000000*10**decimals;	

	 
	uint256 public constant MAX_SUPPLY=INIT_SUPPLY+MINING_SUPPLY+MAX_FUNDING_SUPPLY+TEAM_KEEPING;

	 
	 
	uint256 public totalFundingSupply;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public rate;

	 
	uint256 public constant TEAM_UNFREEZE=40000000*10**decimals;
	bool public hasOneStepWithdraw;
	bool public hasTwoStepWithdraw;
	bool public hasThreeStepWithdraw;
	bool public hasFourStepWithdraw;
	bool public hasFiveStepWithdraw;


	 
	 
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	
	function BTMC(){
		totalSupply=INIT_SUPPLY;
		balances[msg.sender] = INIT_SUPPLY;
		Transfer(0x0, msg.sender, INIT_SUPPLY);
		totalFundingSupply = 0;
	
		 
		startTime=1524499199;
		 
		endTime=1526313600;
		rate=5000;

		hasOneStepWithdraw=false;
		hasTwoStepWithdraw=false;
		hasThreeStepWithdraw=false;
		hasFourStepWithdraw=false;
		hasFiveStepWithdraw=false;




	}

	event CreateBTMC(address indexed _to, uint256 _value);


	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachFundingSupply(uint256 _value,uint256 _rate){
		assert(MAX_FUNDING_SUPPLY>=totalFundingSupply.add(_value.mul(_rate)));
		_;
	}
	modifier assertFalse(bool withdrawStatus){
		assert(!withdrawStatus);
		_;
	}

	modifier notBeforeTime(uint256 targetTime){
		assert(now>targetTime);
		_;
	}

	modifier notAfterTime(uint256 targetTime){
		assert(now<=targetTime);
		_;
	}


	 
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}


	 
	function processFunding(address receiver,uint256 _value,uint256 _rate)  internal
		notReachTotalSupply(_value,_rate)
	{
		uint256 amount=_value.mul(_rate);
		totalSupply=totalSupply.add(amount);
		balances[receiver] +=amount;
		CreateBTMC(receiver,amount);
		Transfer(0x0, receiver, amount);
	}

	function funding (address receiver,uint256 _value,uint256 _rate) whenNotPaused internal 
		notReachFundingSupply(_value,_rate)
	{
		processFunding(receiver,_value,_rate);
		uint256 amount=_value.mul(_rate);
		totalFundingSupply = totalFundingSupply.add(amount);
	}
	

	function () payable external
		notBeforeTime(startTime)
		notAfterTime(endTime)
	{
			funding(msg.sender,msg.value,rate);
	}


	 
	function withdrawForOneStep() external
		onlyOwner
		assertFalse(hasOneStepWithdraw)
		notBeforeTime(1587571200)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		 
		hasOneStepWithdraw = true;
	}

	 
	function withdrawForTwoStep() external
		onlyOwner
		assertFalse(hasTwoStepWithdraw)
		notBeforeTime(1603382400)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		 
		hasTwoStepWithdraw = true;
	}

	 
	function withdrawForThreeStep() external
		onlyOwner
		assertFalse(hasThreeStepWithdraw)
		notBeforeTime(1619107200)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		 
		hasThreeStepWithdraw = true;
	}

	 
	function withdrawForFourStep() external
		onlyOwner
		assertFalse(hasFourStepWithdraw)
		notBeforeTime(1634918400)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		 
		hasFourStepWithdraw = true;
	}

	 
	function withdrawForFiveStep() external
		onlyOwner
		assertFalse(hasFiveStepWithdraw)
		notBeforeTime(1650643200)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		 
		hasFiveStepWithdraw = true;
	}			


  	function transfer(address _to, uint256 _value) whenNotPaused public  returns (bool)
 	{
		require(_to != address(0));
		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}


  	function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) 
  	{
		require(_to != address(0));
		uint256 _allowance = allowed[_from][msg.sender];
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) whenNotPaused public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}


	function setupFundingRate(uint256 _rate) external
		onlyOwner
	{
		rate=_rate;
	}

    function setupFundingTime(uint256 _startTime,uint256 _endTime) external
        onlyOwner
    {
		startTime=_startTime;
		endTime=_endTime;
    }
	  
}