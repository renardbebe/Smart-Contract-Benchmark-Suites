 

pragma solidity 0.4.21;

 

 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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
     
     
     
    return a / b;
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

 

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
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
    emit Transfer(msg.sender, _to, _value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

library AddressArrayUtils {

     
     
    function index(address[] addresses, address a)
        internal pure returns (uint, bool)
    {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}


 
 
 
 
 
contract BsktToken is StandardToken, DetailedERC20, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    struct TokenInfo {
        address addr;
        uint256 quantity;
    }
    uint256 public creationUnit;
    TokenInfo[] public tokens;

    event Create(address indexed creator, uint256 amount);
    event Redeem(address indexed redeemer, uint256 amount, address[] skippedTokens);

     
     
    modifier requireMultiple(uint256 value) {
        require((value % creationUnit) == 0);
        _;
    }

     
     
    modifier requireNonZero(uint256 value) {
        require(value > 0);
        _;
    }

     
     
     
     
     
    function BsktToken(
        address[] addresses,
        uint256[] quantities,
        uint256 _creationUnit,
        string _name,
        string _symbol
    ) DetailedERC20(_name, _symbol, 18) public {
        require(addresses.length > 0);
        require(addresses.length == quantities.length);
        require(_creationUnit >= 1);

        for (uint256 i = 0; i < addresses.length; i++) {
            tokens.push(TokenInfo({
                addr: addresses[i],
                quantity: quantities[i]
            }));
        }

        creationUnit = _creationUnit;
        name = _name;
        symbol = _symbol;
    }

     
     
     
     
     
     
     
     
    function create(uint256 baseUnits)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
         
        require((totalSupply_ + baseUnits) > totalSupply_);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            ERC20 erc20 = ERC20(token.addr);
            uint256 amount = baseUnits.div(creationUnit).mul(token.quantity);
            require(erc20.transferFrom(msg.sender, address(this), amount));
        }

        mint(msg.sender, baseUnits);
        emit Create(msg.sender, baseUnits);
    }

     
     
     
     
     
     
     
    function redeem(uint256 baseUnits, address[] tokensToSkip)
        external
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
        require(baseUnits <= totalSupply_);
        require(baseUnits <= balances[msg.sender]);
        require(tokensToSkip.length <= tokens.length);
         
         

         
        burn(msg.sender, baseUnits);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            ERC20 erc20 = ERC20(token.addr);
            uint256 index;
            bool ok;
            (index, ok) = tokensToSkip.index(token.addr);
            if (ok) {
                continue;
            }
            uint256 amount = baseUnits.div(creationUnit).mul(token.quantity);
            require(erc20.transfer(msg.sender, amount));
        }
        emit Redeem(msg.sender, baseUnits, tokensToSkip);
    }

     
    function tokenAddresses() external view returns (address[]){
        address[] memory addresses = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            addresses[i] = tokens[i].addr;
        }
        return addresses;
    }

     
    function tokenQuantities() external view returns (uint256[]){
        uint256[] memory quantities = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            quantities[i] = tokens[i].quantity;
        }
        return quantities;
    }

     
     
     
     
    function mint(address to, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

     
     
     
     
    function burn(address from, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.sub(amount);
        balances[from] = balances[from].sub(amount);
        emit Transfer(from, address(0), amount);
        return true;
    }

     
     
     
     
    function getQuantity(address token) internal view returns (uint256, bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].addr == token) {
                return (tokens[i].quantity, true);
            }
        }
        return (0, false);
    }

     
     
     
    function withdrawExcessToken(address token)
        external
        onlyOwner
        nonReentrant
    {
        ERC20 erc20 = ERC20(token);
        uint256 withdrawAmount;
        uint256 amountOwned = erc20.balanceOf(address(this));
        uint256 quantity;
        bool ok;
        (quantity, ok) = getQuantity(token);
        if (ok) {
            withdrawAmount = amountOwned.sub(
                totalSupply_.div(creationUnit).mul(quantity)
            );
        } else {
            withdrawAmount = amountOwned;
        }
        require(erc20.transfer(owner, withdrawAmount));
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(this));
        return super.transferFrom(_from, _to, _value);
    }

}