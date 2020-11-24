 

pragma solidity ^0.4.17;

library SafeCalc {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
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
  address public owner;


  function Ownable() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract ERC20Standard {


     
    function totalSupply() public constant returns (uint256) ;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);


    function approve(address _spender, uint256 _value) public returns (bool);

    function balanceOf(address _owner) public constant returns (uint256);

    function allowance(address _owner, address _spender) public constant returns (uint256);
}

contract ERC20StandardToken is ERC20Standard {
    using SafeCalc for uint256;

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;


    function transfer(address to, uint256 value) public returns (bool){
        require(to !=address(0));

        balances[msg.sender]=balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender,to,value);
        return true;
    }


    function transferFrom(address from, address to, uint256 value) public returns (bool){
        require(to != address(0));

        var allowanceAmount = allowances[from][msg.sender];

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowances[from][msg.sender] = allowanceAmount.sub(value);
        Transfer(from, to, value);
        return true;

    }

    function approve(address spender, uint256 value) public returns (bool){
        require((value == 0) || (allowances[msg.sender][spender] == 0));
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256){
        return allowances[owner][spender];
    }


    function balanceOf(address owner) public constant returns (uint256){
        return balances[owner];
    }
}

contract TongToken is ERC20StandardToken, Ownable {

     
    string public constant name = "Tong Token";
    string public constant symbol = "Tong";
    uint256 public constant decimals = 18;
    uint TotalTokenSupply=2100*(10**8)* (10**decimals);

     function totalSupply() public constant returns (uint256 ) {
          return TotalTokenSupply;
      }

     
    address public constant MAIN_HOLDER_ADDR=0x48B7995cA6C311add45071D2267d97a46Aa02a0A;


    function TongToken() public onlyOwner{
        balances[MAIN_HOLDER_ADDR]+=TotalTokenSupply;
        Transfer(0,MAIN_HOLDER_ADDR,TotalTokenSupply);
      }
	  
	 
	  
}