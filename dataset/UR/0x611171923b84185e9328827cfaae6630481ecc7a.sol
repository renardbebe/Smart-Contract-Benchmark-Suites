 

pragma solidity ^0.4.18;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract Pausable is Ownable {

    event EPause();
    event EUnpause();

    bool public paused = true;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }

    function isPaused() view public returns(bool) {
        return paused;
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause();
    }

}

contract StandardToken is ERC20, BasicToken {
  using SafeMath for uint256;
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
contract BurnableToken is PausableToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract Streamity is BurnableToken {

    string public constant name = "Streamity";
    string public constant symbol = "STM";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 180000000 ether;


    address public tokenOwner = 0x99395F3CFa72E30E1073E2DB4d716efCFa1a9b82;
    address public reserveFund = 0xC5fed49Be1F6c3949831a06472aC5AB271AF89BD;  
    address public advisersPartners = 0x5B5521E9D795CA083eF928A58393B8f7FF95e098;  
    address public teamWallet = 0x556dB38b73B97954960cA72580EbdAc89327808E;  


    uint public timeLock = now + 1 years;

    function Streamity () public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[tokenOwner] = INITIAL_SUPPLY;

        balances[this] = balances[tokenOwner].sub(23250000 ether);  
        balances[tokenOwner] = balances[tokenOwner].sub(23250000 ether);
        Transfer(tokenOwner, this, 23250000 ether);

        balances[reserveFund] = balances[tokenOwner].sub(18600000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(18600000 ether);
        Transfer(tokenOwner, reserveFund, 18600000 ether);

        balances[advisersPartners] = balances[tokenOwner].sub(3720000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(3720000 ether);
        Transfer(tokenOwner, advisersPartners, 3720000 ether);

        balances[teamWallet] = balances[tokenOwner].sub(4650000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(4650000 ether);
        Transfer(tokenOwner, teamWallet, 4650000 ether);
    }

    function sendTokens(address _to, uint _value) public onlyOwner {
        require(_to != address(0));
        require(_value <= balances[tokenOwner]);
        balances[tokenOwner] = balances[tokenOwner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(tokenOwner, _to, _value);
    }

    function unlockTeamTokens() public {
        require(now >= timeLock);

        uint amount = 23250000 ether;

        balances[this] = balances[this].sub(amount);
        balances[teamWallet] = balances[teamWallet].add(amount);
        Transfer(this, teamWallet, amount);
    }

}