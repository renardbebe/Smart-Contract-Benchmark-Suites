 

pragma solidity 0.4.23;

 
 
 


 
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


 
 
 

 
library AddressArrayUtils {
  function hasValue(address[] addresses, address value) internal returns (bool) {
    for (uint i = 0; i < addresses.length; i++) {
      if (addresses[i] == value) {
        return true;
      }
    }

    return false;
  }

  function removeByIndex(address[] storage a, uint256 index) internal returns (uint256) {
    a[index] = a[a.length - 1];
    a.length -= 1;
  }
}


 
 
 

 
contract SetInterface {

   
  function issue(uint _quantity) public returns (bool success);
  
   
  function redeem(uint _quantity) public returns (bool success);

  event LogIssuance(
    address indexed _sender,
    uint _quantity
  );

  event LogRedemption(
    address indexed _sender,
    uint _quantity
  );
}



 
contract SetToken is StandardToken, DetailedERC20("EthereumX May 2018 Set", "ETHX-5-18", 18), SetInterface {
  using SafeMath for uint256;
  using AddressArrayUtils for address[];

   
   
   
  struct Component {
    address address_;
    uint unit_;
  }

   
   
   
  uint public naturalUnit;
  Component[] public components;

   
  mapping(bytes32 => bool) internal isComponent;
   
  mapping(uint => mapping(address => uint)) internal unredeemedBalances;


   
   
   
  event LogPartialRedemption(
    address indexed _sender,
    uint _quantity,
    bytes32 _excludedComponents
  );

  event LogRedeemExcluded(
    address indexed _sender,
    bytes32 _components
  );

   
   
   
  modifier hasSufficientBalance(uint quantity) {
     
     
     
    require(balances[msg.sender] >= quantity, "User does not have sufficient balance");
    _;
  }

  modifier validDestination(address _to) {
    require(_to != address(0));
    require(_to != address(this));
    _;
  }

  modifier isMultipleOfNaturalUnit(uint _quantity) {
    require((_quantity % naturalUnit) == 0);
    _;
  }

  modifier isNonZero(uint _quantity) {
    require(_quantity > 0);
    _;
  }

   
  constructor(address[] _components, uint[] _units, uint _naturalUnit)
    isNonZero(_naturalUnit)
    public {
     
    require(_components.length > 0, "Component length needs to be great than 0");

     
    require(_units.length > 0, "Units must be greater than 0");

     
    require(_components.length == _units.length, "Component and unit lengths must be the same");

    naturalUnit = _naturalUnit;

     
     

     
     
    for (uint16 i = 0; i < _units.length; i++) {
       
      uint currentUnits = _units[i];
      require(currentUnits > 0, "Unit declarations must be non-zero");

       
      address currentComponent = _components[i];
      require(currentComponent != address(0), "Components must have non-zero address");

       
      require(!tokenIsComponent(currentComponent));

       
      isComponent[keccak256(currentComponent)] = true;

      components.push(Component({
        address_: currentComponent,
        unit_: currentUnits
      }));
    }
  }

   
   
   

   
  function issue(uint _quantity)
    isMultipleOfNaturalUnit(_quantity)
    isNonZero(_quantity)
    public returns (bool success) {
     
     
     
    for (uint16 i = 0; i < components.length; i++) {
      address currentComponent = components[i].address_;
      uint currentUnits = components[i].unit_;

      uint preTransferBalance = ERC20(currentComponent).balanceOf(this);

      uint transferValue = calculateTransferValue(currentUnits, _quantity);
      require(ERC20(currentComponent).transferFrom(msg.sender, this, transferValue));

       
      uint postTransferBalance = ERC20(currentComponent).balanceOf(this);
      assert(preTransferBalance.add(transferValue) == postTransferBalance);
    }

    mint(_quantity);

    emit LogIssuance(msg.sender, _quantity);

    return true;
  }

   
  function redeem(uint _quantity)
    public
    isMultipleOfNaturalUnit(_quantity)
    hasSufficientBalance(_quantity)
    isNonZero(_quantity)
    returns (bool success)
  {
    burn(_quantity);

    for (uint16 i = 0; i < components.length; i++) {
      address currentComponent = components[i].address_;
      uint currentUnits = components[i].unit_;

      uint preTransferBalance = ERC20(currentComponent).balanceOf(this);

      uint transferValue = calculateTransferValue(currentUnits, _quantity);
      require(ERC20(currentComponent).transfer(msg.sender, transferValue));

       
      uint postTransferBalance = ERC20(currentComponent).balanceOf(this);
      assert(preTransferBalance.sub(transferValue) == postTransferBalance);
    }

    emit LogRedemption(msg.sender, _quantity);

    return true;
  }

   
  function partialRedeem(uint _quantity, bytes32 _componentsToExclude)
    public
    isMultipleOfNaturalUnit(_quantity)
    isNonZero(_quantity)
    hasSufficientBalance(_quantity)
    returns (bool success)
  {
     
     
    require(_componentsToExclude > 0, "Excluded components must be non-zero");

    burn(_quantity);

    for (uint16 i = 0; i < components.length; i++) {
      uint transferValue = calculateTransferValue(components[i].unit_, _quantity);

       
       
      if (_componentsToExclude & bytes32(2 ** i) > 0) {
        unredeemedBalances[i][msg.sender] += transferValue;
      } else {
        uint preTransferBalance = ERC20(components[i].address_).balanceOf(this);

        require(ERC20(components[i].address_).transfer(msg.sender, transferValue));

         
        uint postTransferBalance = ERC20(components[i].address_).balanceOf(this);
        assert(preTransferBalance.sub(transferValue) == postTransferBalance);
      }
    }

    emit LogPartialRedemption(msg.sender, _quantity, _componentsToExclude);

    return true;
  }

   
  function redeemExcluded(bytes32 _componentsToRedeem)
    public
    returns (bool success)
  {
    require(_componentsToRedeem > 0, "Components to redeem must be non-zero");

    for (uint16 i = 0; i < components.length; i++) {
      if (_componentsToRedeem & bytes32(2 ** i) > 0) {
        address currentComponent = components[i].address_;
        uint remainingBalance = unredeemedBalances[i][msg.sender];

         
        unredeemedBalances[i][msg.sender] = 0;

        require(ERC20(currentComponent).transfer(msg.sender, remainingBalance));
      }
    }

    emit LogRedeemExcluded(msg.sender, _componentsToRedeem);

    return true;
  }

   
   
   
  function getComponents() public view returns(address[]) {
    address[] memory componentAddresses = new address[](components.length);
    for (uint16 i = 0; i < components.length; i++) {
        componentAddresses[i] = components[i].address_;
    }
    return componentAddresses;
  }

  function getUnits() public view returns(uint[]) {
    uint[] memory units = new uint[](components.length);
    for (uint16 i = 0; i < components.length; i++) {
        units[i] = components[i].unit_;
    }
    return units;
  }

  function getUnredeemedBalance(address _componentAddress, address _userAddress) public view returns (uint256) {
    require(tokenIsComponent(_componentAddress));

    uint componentIndex;

    for (uint i = 0; i < components.length; i++) {
      if (components[i].address_ == _componentAddress) {
        componentIndex = i;
      }
    }

    return unredeemedBalances[componentIndex][_userAddress];
  }

   
   
   
  function transfer(address _to, uint256 _value) validDestination(_to) public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) validDestination(_to) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
   

  function tokenIsComponent(address _tokenAddress) view internal returns (bool) {
    return isComponent[keccak256(_tokenAddress)];
  }

  function calculateTransferValue(uint componentUnits, uint quantity) view internal returns(uint) {
    return quantity.div(naturalUnit).mul(componentUnits);
  }

  function mint(uint quantity) internal {
    balances[msg.sender] = balances[msg.sender].add(quantity);
    totalSupply_ = totalSupply_.add(quantity);
    emit Transfer(address(0), msg.sender, quantity);
  }

  function burn(uint quantity) internal {
    balances[msg.sender] = balances[msg.sender].sub(quantity);
    totalSupply_ = totalSupply_.sub(quantity);
    emit Transfer(msg.sender, address(0), quantity);
  }
}