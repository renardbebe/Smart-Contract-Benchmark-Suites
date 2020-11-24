 

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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract Object is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    bool public mintingFinished = false;

    event Burn(address indexed burner, uint value);
    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function Object(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function burn(uint _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value % (1 ether) == 0);  

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract Shop is Ownable {
    using SafeMath for *;

    struct ShopSettings {
        address bank;
        uint32 startTime;
        uint32 endTime;
        uint fundsRaised;
        uint rate;
        uint price;
         
    }

    Object public object;
    ShopSettings public shopSettings;

    modifier onlyValidPurchase() {
        require(msg.value % shopSettings.price == 0);  
        require((now >= shopSettings.startTime && now <= shopSettings.endTime) && msg.value != 0);
        _;
    }

    modifier whenClosed() {  
        require(now > shopSettings.endTime);
        _;
    }

    modifier whenOpen() {
        require(now < shopSettings.endTime);
        _;
    }

    modifier onlyValidAddress(address _bank) {
        require(_bank != address(0));
        _;
    }

    modifier onlyOne() {
        require(calculateTokens() == 1 ether);
        _;
    }

    modifier onlyBuyer(address _beneficiary) {
        require(_beneficiary == msg.sender);
        _;
    }

    event ShopClosed(uint32 date);
    event ObjectPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function () external payable {
        buyObject(msg.sender);
    }

    function Shop(address _bank, string _name, string _symbol, uint _rate, uint32 _endTime)
    onlyValidAddress(_bank) public {
        require(_rate >= 0);
        require(_endTime > now);
        shopSettings = ShopSettings(_bank, uint32(now), _endTime, 0, _rate, 0);
        calculatePrice();  
        object = new Object(_name, _symbol);
    }

    function buyObject(address _beneficiary) onlyValidPurchase
    onlyBuyer(_beneficiary)
    onlyValidAddress(_beneficiary) public payable {
        uint numTokens = calculateTokens();
        shopSettings.fundsRaised = shopSettings.fundsRaised.add(msg.value);
        object.mint(_beneficiary, numTokens);
        ObjectPurchase(msg.sender, _beneficiary, msg.value, numTokens);
        forwardFunds();
    }

    function calculateTokens() internal returns(uint) {
         
         
         
        calculatePrice();  
        return msg.value.mul(1 ether).div(1 ether.mul(1 ether).div(shopSettings.rate));
    }

    function calculatePrice() internal returns(uint) {
        shopSettings.price = (1 ether).mul(1 ether).div(shopSettings.rate);  
         
    }

    function closeShop() onlyOwner whenOpen public {
        shopSettings.endTime = uint32(now);
        ShopClosed(uint32(now));
    }

    function forwardFunds() internal {
        shopSettings.bank.transfer(msg.value);
    }
}