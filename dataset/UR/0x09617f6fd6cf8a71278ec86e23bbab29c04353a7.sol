 

pragma solidity ^0.4.13;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
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

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract ULToken is PausableToken {

    string public name;                              

    uint8 public decimals;                           

    string public symbol;                            



    bool public ownerBurnOccurred;                    

    uint256 public licenseCostNumerator;             

    uint256 public licenseCostDenominator;           

    uint256 public totalLicensePurchases;            

    mapping (address => bool) public ownsLicense;    



     

    modifier afterOwnerBurn() {

        require(ownerBurnOccurred == true);

        _;

    }



     

    event LogOwnerBurn(address indexed owner, uint256 value);

     

    event LogPurchaseLicense(address indexed purchaser, uint256 indexed license_num, uint256 value, bytes32 indexed data);

     

    event LogChangedLicenseCost(uint256 numerator, uint256 denominator);



     

    function transferOwnership(address newOwner) onlyOwner public {

        revert();

    }



     

    function ULToken(

        uint256 _initialAmount,

        string _tokenName,

        uint8 _decimalUnits,

        string _tokenSymbol

    ) public {

        balances[msg.sender] = _initialAmount;       

        totalSupply = _initialAmount;                

        name = _tokenName;                           

        decimals = _decimalUnits;                    

        symbol = _tokenSymbol;                       



        owner = msg.sender;                          



        ownerBurnOccurred = false;                    



        licenseCostNumerator = 0;                    

        licenseCostDenominator = 1;

        totalLicensePurchases = 0;

    }



     

    function ownerBurn(

        uint256 _numerator,

        uint256 _denominator

    ) public

        whenNotPaused

        onlyOwner

    returns (bool) {

         

        require(ownerBurnOccurred == false);

         

        changeLicenseCost(_numerator, _denominator);

         

        uint256 value = balances[msg.sender];

        balances[msg.sender] -= value;

        totalSupply -= value;

        ownerBurnOccurred = true;

        LogOwnerBurn(msg.sender, value);

        return true;

    }



     

    function changeLicenseCost(

        uint256 _numerator,

        uint256 _denominator

    ) public

        whenNotPaused

        onlyOwner

    returns (bool) {

        require(_numerator >= 0);

        require(_denominator > 0);

        require(_numerator < _denominator);

        licenseCostNumerator = _numerator;

        licenseCostDenominator = _denominator;

        LogChangedLicenseCost(licenseCostNumerator, licenseCostDenominator);

        return true;

    }



     

    function purchaseLicense(bytes32 _data) public

        whenNotPaused

        afterOwnerBurn

    returns (bool) {

        require(ownsLicense[msg.sender] == false);

         

        uint256 costNumerator = totalSupply * licenseCostNumerator;

        uint256 cost = costNumerator / licenseCostDenominator;

        require(balances[msg.sender] >= cost);

         

        balances[msg.sender] -= cost;

        totalSupply -= cost;

         

        ownsLicense[msg.sender] = true;

        totalLicensePurchases += 1;

        LogPurchaseLicense(msg.sender, totalLicensePurchases, cost, _data);

        return true;

    }

}