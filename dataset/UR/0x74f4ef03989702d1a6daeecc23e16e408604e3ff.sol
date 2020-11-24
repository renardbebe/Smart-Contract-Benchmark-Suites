 

pragma solidity ^0.4.13;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract PGDToken is StandardToken,Ownable{

	 
	string public constant name="pagoda coin";
	string public constant symbol="PGD";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_SUPPLY=200000000*10**decimals;
	uint256 public constant MAX_FUNDING_SUPPLY=100000000*10**decimals;
	 
	uint256 public constant TEAM_KEEPING=100000000*10**decimals;

	uint256 public constant rate=17000;
	
	uint256 public totalFundingSupply;
	uint256 public totalTeamWithdrawSupply;

	uint256 public startBlock;
	uint256 public endBlock;
	address[] public allFundingUsers;

	mapping(address=>uint256) public fundBalance;
	

	function PGDToken(){
		totalSupply = 0 ;
		totalFundingSupply = 0;
		totalTeamWithdrawSupply=0;

		startBlock = 4000000;
		endBlock = 6000000;
	}

	modifier beforeBlock(uint256 _blockNum){
		assert(getCurrentBlockNum()<_blockNum);
		_;
	}

	modifier afterBlock(uint256 _blockNum){
		assert(getCurrentBlockNum()>=_blockNum);
		_;
	}

	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachFundingSupply(uint256 _value,uint256 _rate){
		assert(MAX_FUNDING_SUPPLY>=totalFundingSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachTeamWithdrawSupply(uint256 _value,uint256 _rate){
		assert(TEAM_KEEPING>=totalTeamWithdrawSupply.add(_value.mul(_rate)));
		_;
	}

	 
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}


	 
	function () payable external
		afterBlock(startBlock)
		beforeBlock(endBlock)
		notReachFundingSupply(msg.value,rate)
	{
			processFunding(msg.sender,msg.value,rate);
			 
			uint256 amount=msg.value.mul(rate);
			totalFundingSupply = totalFundingSupply.add(amount);
			
			 
			allFundingUsers.push(msg.sender);
			fundBalance[msg.sender]=fundBalance[msg.sender].add(amount);


	}

	 
	function airdrop(address receiver,uint256 _value) external
	    onlyOwner
		afterBlock(endBlock)
		notReachFundingSupply(_value,1)
	{
		processFunding(receiver,_value,1);
		 
		totalFundingSupply=totalFundingSupply.add(_value);
	}

	 
	function patformWithdraw(uint256 _value) external
		onlyOwner
		notReachTeamWithdrawSupply(_value,1)

	{
		processFunding(msg.sender,_value,1);
		 
		totalTeamWithdrawSupply=totalTeamWithdrawSupply.add(_value);

	}
	 
	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
		notReachTotalSupply(_value,_rate)
	{
		uint256 amount=_value.mul(_rate);
		totalSupply=totalSupply.add(amount);
		balances[receiver] +=amount;
		Transfer(0x0, receiver, amount);
	}


	function getCurrentBlockNum() internal returns (uint256){
		return block.number;
	}



    function setupFundingInfo(uint256 _startBlock,uint256 _endBlock) external
        onlyOwner
    {
		startBlock=_startBlock;
		endBlock=_endBlock;
    }
}