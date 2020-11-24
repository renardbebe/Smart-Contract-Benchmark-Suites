 

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

 

library AddressArrayUtils {

     
    function index(address[] addresses, address a) internal pure returns (uint, bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}


 
 
 
 
 
 
contract BasketToken is StandardToken, Pausable {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    string constant public name = "ERC20 TWENTY";
    string constant public symbol = "ETW";
    uint8 constant public decimals = 18;
    struct TokenInfo {
        address addr;
        uint256 tokenUnits;
    }
    uint256 private creationQuantity_;
    TokenInfo[] public tokens;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

     
     
    modifier requireMultiple(uint256 value) {
        require((value % creationQuantity_) == 0);
        _;
    }

     
     
    modifier requireNonZero(uint256 value) {
        require(value > 0);
        _;
    }

     
     
     
     
     
    function BasketToken(
        address[] addresses,
        uint256[] tokenUnits,
        uint256 _creationQuantity
    ) public {
        require(0 < addresses.length && addresses.length < 256);
        require(addresses.length == tokenUnits.length);
        require(_creationQuantity >= 1);

        creationQuantity_ = _creationQuantity;

        for (uint8 i = 0; i < addresses.length; i++) {  
            tokens.push(TokenInfo({
                addr: addresses[i],
                tokenUnits: tokenUnits[i]
            }));
        }
    }

     
     
     
     
    function creationQuantity() external view returns(uint256) {
        return creationQuantity_;
    }

     
     
     
     
     
     
     
     
     
    function create(uint256 baseUnits)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
         
        require((totalSupply_ + baseUnits) > totalSupply_);

        for (uint8 i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            ERC20 erc20 = ERC20(tokenInfo.addr);
            uint256 amount = baseUnits.div(creationQuantity_).mul(tokenInfo.tokenUnits);
            require(erc20.transferFrom(msg.sender, address(this), amount));
        }

        mint(msg.sender, baseUnits);
    }

     
     
     
     
     
     
     
    function redeem(uint256 baseUnits, address[] tokensToSkip)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
        require((totalSupply_ >= baseUnits));
        require((balances[msg.sender] >= baseUnits));
        require(tokensToSkip.length <= tokens.length);

         
        burn(msg.sender, baseUnits);

        for (uint8 i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            ERC20 erc20 = ERC20(tokenInfo.addr);
            uint256 index;
            bool ok;
            (index, ok) = tokensToSkip.index(tokenInfo.addr);
            if (ok) {
                continue;
            }
            uint256 amount = baseUnits.div(creationQuantity_).mul(tokenInfo.tokenUnits);
            require(erc20.transfer(msg.sender, amount));
        }
    }

     
    function tokenAddresses() external view returns (address[]){
        address[] memory tokenAddresses = new address[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            tokenAddresses[i] = tokens[i].addr;
        }
        return tokenAddresses;
    }

     
    function tokenUnits() external view returns (uint256[]){
        uint256[] memory tokenUnits = new uint256[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            tokenUnits[i] = tokens[i].tokenUnits;
        }
        return tokenUnits;
    }

     
     
     
     
    function mint(address to, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }

     
     
     
     
    function burn(address from, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.sub(amount);
        balances[from] = balances[from].sub(amount);
        Burn(from, amount);
        Transfer(from, address(0), amount);
        return true;
    }

     
     
     
     
    function getTokenUnits(address token) internal view returns (uint256, bool) {
        for (uint8 i = 0; i < tokens.length; i++) {
            if (tokens[i].addr == token) {
                return (tokens[i].tokenUnits, true);
            }
        }
        return (0, false);
    }

     
     
     
    function withdrawExcessToken(address token)
        external
        onlyOwner
    {
        ERC20 erc20 = ERC20(token);
        uint256 withdrawAmount;
        uint256 amountOwned = erc20.balanceOf(address(this));
        uint256 tokenUnits;
        bool ok;
        (tokenUnits, ok) = getTokenUnits(token);
        if (ok) {
            withdrawAmount = amountOwned.sub(totalSupply_.div(creationQuantity_).mul(tokenUnits));
        } else {
            withdrawAmount = amountOwned;
        }
        require(erc20.transfer(owner, withdrawAmount));
    }

     
    function withdrawEther()
        external
        onlyOwner
    {
        owner.transfer(this.balance);
    }

     
    function() external payable {
    }

}