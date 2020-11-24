 

 

 
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

 
library SafeMathUint256 {
    using SafeMath for uint256;

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

     
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return a.mul(b).div(base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return a.mul(base).div(b);
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

 
contract Set {
  function issue(uint quantity) public returns (bool success);
  function redeem(uint quantity) public returns (bool success);

  event LogIssuance(
    address indexed _sender,
    uint indexed _quantity
  );

  event LogRedemption(
    address indexed _sender,
    uint indexed _quantity
  );
}


 
contract SetToken is StandardToken, DetailedERC20("Decentralized Exchange", "DEX", 18), Set {
  using SafeMathUint256 for uint256;

   
   
   
  struct Component {
    address address_;
    uint unit_;
  }

  struct UnredeemedComponent {
    uint balance;
    bool isRedeemed;
  }

   
   
   
  uint public naturalUnit;
  Component[] public components;
  mapping(address => bool) internal isComponent;
   
  mapping(address => mapping(address => UnredeemedComponent)) public unredeemedComponents;


   
   
   
  event LogPartialRedemption(
    address indexed _sender,
    uint indexed _quantity,
    address[] _excludedComponents
  );

  event LogRedeemExcluded(
    address indexed _sender,
    address[] _components
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

   
  constructor(address[] _components, uint[] _units, uint _naturalUnit) public {
     
    require(_components.length > 0, "Component length needs to be great than 0");

     
    require(_units.length > 0, "Units must be greater than 0");

     
    require(_components.length == _units.length, "Component and unit lengths must be the same");

    require(_naturalUnit > 0);
    naturalUnit = _naturalUnit;

     
     

     
     
    for (uint i = 0; i < _units.length; i++) {
       
      uint currentUnits = _units[i];
      require(currentUnits > 0, "Unit declarations must be non-zero");

       
      address currentComponent = _components[i];
      require(currentComponent != address(0), "Components must have non-zero address");

       
      isComponent[currentComponent] = true;

      components.push(Component({
        address_: currentComponent,
        unit_: currentUnits
      }));
    }
  }

   
  function () payable {
    revert();
  }

   
   
   

   
  function issue(uint quantity)
    isMultipleOfNaturalUnit(quantity)
    isNonZero(quantity)
    public returns (bool success) {
     
     
     
    for (uint i = 0; i < components.length; i++) {
      address currentComponent = components[i].address_;
      uint currentUnits = components[i].unit_;

      uint transferValue = calculateTransferValue(currentUnits, quantity);

      assert(ERC20(currentComponent).transferFrom(msg.sender, this, transferValue));
    }

    mint(quantity);

    emit LogIssuance(msg.sender, quantity);

    return true;
  }

   
  function redeem(uint quantity)
    public
    isMultipleOfNaturalUnit(quantity)
    hasSufficientBalance(quantity)
    isNonZero(quantity)
    returns (bool success)
  {
    burn(quantity);

    for (uint i = 0; i < components.length; i++) {
      address currentComponent = components[i].address_;
      uint currentUnits = components[i].unit_;

      uint transferValue = calculateTransferValue(currentUnits, quantity);

       
      assert(ERC20(currentComponent).transfer(msg.sender, transferValue));
    }

    emit LogRedemption(msg.sender, quantity);

    return true;
  }

   
  function partialRedeem(uint quantity, address[] excludedComponents)
    public
    isMultipleOfNaturalUnit(quantity)
    isNonZero(quantity)
    hasSufficientBalance(quantity)
    returns (bool success)
  {
     
     
    require(
      excludedComponents.length < components.length,
      "Excluded component length must be less than component length"
    );
    require(excludedComponents.length > 0, "Excluded components must be non-zero");

    burn(quantity);

    for (uint i = 0; i < components.length; i++) {
      bool isExcluded = false;

      uint transferValue = calculateTransferValue(components[i].unit_, quantity);

       
       
      for (uint j = 0; j < excludedComponents.length; j++) {
        address currentExcluded = excludedComponents[j];

         
        assert(isComponent[currentExcluded]);

         
        if (components[i].address_ == currentExcluded) {
           
           
          bool currentIsRedeemed = unredeemedComponents[components[i].address_][msg.sender].isRedeemed;
          assert(currentIsRedeemed == false);

          unredeemedComponents[components[i].address_][msg.sender].balance += transferValue;

           
          unredeemedComponents[components[i].address_][msg.sender].isRedeemed = true;

          isExcluded = true;
        }
      }

      if (!isExcluded) {
        assert(ERC20(components[i].address_).transfer(msg.sender, transferValue));
      }
    }

     
    for (uint k = 0; k < excludedComponents.length; k++) {
      address currentExcludedToUnredeem = excludedComponents[k];
      unredeemedComponents[currentExcludedToUnredeem][msg.sender].isRedeemed = false;
    }

    emit LogPartialRedemption(msg.sender, quantity, excludedComponents);

    return true;
  }

   
  function redeemExcluded(address[] componentsToRedeem, uint[] quantities)
    public
    returns (bool success)
  {
    require(quantities.length > 0, "Quantities must be non-zero");
    require(componentsToRedeem.length > 0, "Components redeemed must be non-zero");
    require(quantities.length == componentsToRedeem.length, "Lengths must be the same");

    for (uint i = 0; i < quantities.length; i++) {
      address currentComponent = componentsToRedeem[i];
      uint currentQuantity = quantities[i];

       
      uint remainingBalance = unredeemedComponents[currentComponent][msg.sender].balance;
      require(remainingBalance >= currentQuantity);

       
      unredeemedComponents[currentComponent][msg.sender].balance = remainingBalance.sub(currentQuantity);

      assert(ERC20(currentComponent).transfer(msg.sender, currentQuantity));
    }

    emit LogRedeemExcluded(msg.sender, componentsToRedeem);

    return true;
  }

   
   
   

  function componentCount() public view returns(uint componentsLength) {
    return components.length;
  }

  function getComponents() public view returns(address[]) {
    address[] memory componentAddresses = new address[](components.length);
    for (uint i = 0; i < components.length; i++) {
        componentAddresses[i] = components[i].address_;
    }
    return componentAddresses;
  }

  function getUnits() public view returns(uint[]) {
    uint[] memory units = new uint[](components.length);
    for (uint i = 0; i < components.length; i++) {
        units[i] = components[i].unit_;
    }
    return units;
  }

   
   
   
  function transfer(address _to, uint256 _value) validDestination(_to) public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) validDestination(_to) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
   

  function calculateTransferValue(uint componentUnits, uint quantity) internal returns(uint) {
    return quantity.div(naturalUnit).mul(componentUnits);
  }

  function mint(uint quantity) internal {
     
    balances[msg.sender] = balances[msg.sender].add(quantity);

     
    totalSupply_ = totalSupply_.add(quantity);
  }

  function burn(uint quantity) internal {
    balances[msg.sender] = balances[msg.sender].sub(quantity);
    totalSupply_ = totalSupply_.sub(quantity);
  }
}