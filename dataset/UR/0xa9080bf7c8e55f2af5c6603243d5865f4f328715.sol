 

pragma solidity ^0.4.18;

 

 
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
 
 
 
 
 
 
 

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MAR is MintableToken, Pausable {
  string public constant name = "MAR";
  string public constant symbol = "MAR";
  uint8 public constant decimals = 18;
  uint256 internal constant MILLION_TOKENS = 1e6 * 1e18;

  address public teamWallet;
  bool public teamTokensMinted = false;
  uint256 public circulationStartTime;

  event Burn(address indexed burnedFrom, uint256 value);

  function MARToken() public {
    paused = true;
  }

  function setTeamWallet(address _teamWallet) public onlyOwner canMint {
    require(teamWallet == address(0));
    require(_teamWallet != address(0));

    teamWallet = _teamWallet;
  }
  
  
   function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply + _amount <= 1000 * MILLION_TOKENS && circulationStartTime != 0);
    if(now > circulationStartTime && now < circulationStartTime + 2 years)
    {
        require(totalSupply + _amount <= 450 * MILLION_TOKENS);
    }
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
    



   
  function unpause() onlyOwner whenPaused public {
    if (circulationStartTime == 0) {
      circulationStartTime = now;
    }

    super.unpause();
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(validTransfer(msg.sender, _value));
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(validTransfer(_from, _value));
    return super.transferFrom(_from, _to, _value);
  }

  function validTransfer(address _from, uint256 _amount) internal view returns (bool) {
    if (_from != teamWallet) {
      return true;
    }

    uint256 balanceAfterTransfer = balanceOf(_from).sub(_amount);
    return balanceAfterTransfer >= minimumTeamWalletBalance();
  }

  
  function minimumTeamWalletBalance() internal view returns (uint256) {
    if (now < circulationStartTime + 2 years) {
      return 550 * MILLION_TOKENS;
    } else {
      return 0;
    }
  }

   
  function burn(address _from, uint256 _value) external onlyOwner {
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);
  }
}