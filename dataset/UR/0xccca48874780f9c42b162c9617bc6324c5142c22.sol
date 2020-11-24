 

pragma solidity ^0.4.14;


 


 
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
    require(_value <= balances[msg.sender]);

     
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

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

 

contract SatanCoin is StandardToken {
  
  using SafeMath for uint;

  string public constant name = "SatanCoin";
  string public constant symbol = "SATAN";
  uint public constant decimals = 0;

  address public owner = msg.sender;
   
  uint public constant rate = .0666 ether;

  uint public roundNum = 0;
  uint public constant roundMax = 74;
  uint public roundDeadline;
  bool public roundActive = false;
  uint tokenAmount;
  uint roundBuyersNum;

  mapping(uint => address) buyers;

  event Raffled(uint roundNumber, address winner, uint amount);
  event RoundStart(uint roundNumber);
  event RoundEnd(uint roundNumber);

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }

  function ()
    payable
  {
    createTokens(msg.sender);
  }

  function createTokens(address receiver)
    public
    payable
  {
     
    require(roundActive);
     
    require(msg.value > 0);
     
    require((msg.value % rate) == 0);

    tokenAmount = msg.value.div(rate);

     
    require(tokenAmount <= getRoundRemaining());
     
    require((tokenAmount+totalSupply) <= 666);
     
    require(tokenAmount >= 1);

     
    totalSupply = totalSupply.add(tokenAmount);
    balances[receiver] = balances[receiver].add(tokenAmount);

     
    for(uint i = 0; i < tokenAmount; i++)
    {
      buyers[i.add(getRoundIssued())] = receiver;
    }

     
    owner.transfer(msg.value);
  }

  function startRound()
    public
    onlyOwner
    returns (bool)
  {
    require(!roundActive); 
    require(roundNum<9);  
     
    roundActive = true;
    roundDeadline = now + 6 days;
    roundNum++;

    RoundStart(roundNum);
    return true;
  }

  function endRound()
    public
    onlyOwner
    returns (bool)
  {
     require(roundDeadline < now);
      
    if(getRoundRemaining() == 74)
    {
      totalSupply = totalSupply.add(74);
      balances[owner] = balances[owner].add(74);
    }  
    else if(getRoundRemaining() != 0) assert(raffle(getRoundRemaining()));

    roundActive = false;

    RoundEnd(roundNum);
    return true;
  }

  function raffle(uint raffleAmount)
    private
    returns (bool)
  {
     
    uint randomIndex = uint(block.blockhash(block.number))%(roundMax-raffleAmount)+1;
    address receiver = buyers[randomIndex];

    totalSupply = totalSupply.add(raffleAmount);
    balances[receiver] = balances[receiver].add(raffleAmount);

    Raffled(roundNum, receiver, raffleAmount);
    return true;
  }

  function getRoundRemaining()
    public
    constant
    returns (uint)
  {
    return roundNum.mul(roundMax).sub(totalSupply);
  }

   function getRoundIssued()
    public
    constant
    returns (uint)
  {
    return totalSupply.sub((roundNum-1).mul(roundMax));
  }
}