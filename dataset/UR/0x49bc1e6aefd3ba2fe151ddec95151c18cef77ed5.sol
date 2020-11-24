 

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

contract GCV is ERC20,Ownable{
	using SafeMath for uint256;

	 
	string public constant name="gemstone chain value";
	string public constant symbol="GCV";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint256 public constant MAX_SUPPLY=10000000000*10**decimals;
	uint256 public constant INIT_SUPPLY=9980000000*10**decimals;

	uint256 public constant autoAirdropAmount=100*10**decimals;
	uint256 public alreadyAutoAirdropAmount;

	uint256 public airdropSupply;
	mapping(address => bool) touched;


	function GCV(){
		airdropSupply = 0;
		totalSupply = INIT_SUPPLY;
		balances[msg.sender] = INIT_SUPPLY;
		Transfer(0x0, msg.sender, INIT_SUPPLY);
	}

    function addIssue (uint256 _amount) external
    	onlyOwner
    {
    	balances[msg.sender] = balances[msg.sender].add(_amount);
    }
    
    function airdrop(address [] _holders,uint256 paySize) external
    	onlyOwner 
	{
        uint256 count = _holders.length;
        assert(paySize.mul(count) <= balanceOf(msg.sender));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], paySize);
			airdropSupply = airdropSupply.add(paySize);
        }
    }

  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));

        if( !touched[msg.sender] && totalSupply.add(autoAirdropAmount) <= MAX_SUPPLY ){
            touched[msg.sender] = true;
            balances[msg.sender] = balances[msg.sender].add( autoAirdropAmount );
            totalSupply = totalSupply.add( autoAirdropAmount );
            alreadyAutoAirdropAmount=alreadyAutoAirdropAmount.add(autoAirdropAmount);

        }
        
        require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
        if( totalSupply.add(autoAirdropAmount) <= MAX_SUPPLY ){
            if( touched[_owner] ){
                return balances[_owner];
            }
            else{
                return balances[_owner].add(autoAirdropAmount);
            }
        } else {
            return balances[_owner];
        }
  	}

  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));
        
        if( !touched[_from] && totalSupply.add(autoAirdropAmount) <= MAX_SUPPLY ){
            touched[_from] = true;
            balances[_from] = balances[_from].add( autoAirdropAmount );
            totalSupply = totalSupply.add( autoAirdropAmount );
            alreadyAutoAirdropAmount=alreadyAutoAirdropAmount.add(autoAirdropAmount);
        }
        
        require(_value <= balances[_from]);


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