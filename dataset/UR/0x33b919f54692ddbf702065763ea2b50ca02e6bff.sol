 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract FreezableToken is Ownable {

    mapping (address => bool) public frozenList;

    event FrozenFunds(address indexed wallet, bool frozen);

     
    function freezeAccount(address _wallet) public onlyOwner {
        require(
            _wallet != address(0),
            "Address must be not empty"
        );
        frozenList[_wallet] = true;
        emit FrozenFunds(_wallet, true);
    }

     
    function unfreezeAccount(address _wallet) public onlyOwner {
        require(
            _wallet != address(0),
            "Address must be not empty"
        );
        frozenList[_wallet] = false;
        emit FrozenFunds(_wallet, false);
    }

      
    function isFrozen(address _wallet) public view returns (bool) {
        return frozenList[_wallet];
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

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData)
    external;
}


contract MocrowCoin is StandardToken, BurnableToken, FreezableToken, Pausable {
    string public constant name = "MOCROW";
    string public constant symbol = "MCW";
    uint8 public constant decimals = 18;

    uint256 public constant RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION = 201700456 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS = 113010700 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ROI_ON_CAPITAL = 9626337 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION = 77010700 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_CYNOTRUST = 11551604 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES = 244936817 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT = 11551604 * (10 ** uint256(decimals));

    uint256 public constant RESERVED_TOKENS_FOR_PRE_ICO = 59561520 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ICO = 139999994 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ICO_BONUSES = 15756152 * (10 ** uint256(decimals));

    uint256 public constant TOTAL_SUPPLY_VALUE = 884705884 * (10 ** uint256(decimals));

    address public addressIco;

    bool isIcoSet = false;

    modifier onlyIco() {
        require(
            msg.sender == addressIco,
            "Address must be the address of the ICO"
        );
        _;
    }

     
    constructor(
        address _foundersFoundationReserve,
        address _platformOperationsReserve,
        address _roiOnCapitalReserve,
        address _financialInstitutionReserve,
        address _cynotrustReserve,
        address _cryptoExchangesReserve,
        address _furtherTechDevelopmentReserve) public
        {
        require(
            _foundersFoundationReserve != address(0) && 
            _platformOperationsReserve != address(0) && _roiOnCapitalReserve != address(0) && _financialInstitutionReserve != address(0),
            "Addresses must be not empty"
        );

        require(
            _cynotrustReserve != address(0) && 
            _cryptoExchangesReserve != address(0) && _furtherTechDevelopmentReserve != address(0),
            "Addresses must be not empty"
        );

        balances[_foundersFoundationReserve] = RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION);
        emit Transfer(address(0), _foundersFoundationReserve, RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION);

        balances[_platformOperationsReserve] = RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS);
        emit Transfer(address(0), _platformOperationsReserve, RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS);

        balances[_roiOnCapitalReserve] = RESERVED_TOKENS_FOR_ROI_ON_CAPITAL;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_ROI_ON_CAPITAL);
        emit Transfer(address(0), _roiOnCapitalReserve, RESERVED_TOKENS_FOR_ROI_ON_CAPITAL);

        balances[_financialInstitutionReserve] = RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION);
        emit Transfer(address(0), _financialInstitutionReserve, RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION);

        balances[_cynotrustReserve] = RESERVED_TOKENS_FOR_CYNOTRUST;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_CYNOTRUST);
        emit Transfer(address(0), _cynotrustReserve, RESERVED_TOKENS_FOR_CYNOTRUST);

        balances[_cryptoExchangesReserve] = RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES);
        emit Transfer(address(0), _cryptoExchangesReserve, RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES);

        balances[_furtherTechDevelopmentReserve] = RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT);
        emit Transfer(address(0), _furtherTechDevelopmentReserve, RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(
            !isFrozen(msg.sender),
            "Transfer possibility must be unfrozen for the address"
        );
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(
            !isFrozen(msg.sender),
            "Transfer possibility must be unfrozen for the address"
        );
        require(
            !isFrozen(_from),
            "Transfer possibility must be unfrozen for the address"
        );
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function setIco(address _addressIco) public onlyOwner {
        require(
            _addressIco != address(0),
            "Address must be not empty"
        );

        require(
            !isIcoSet,
            "ICO address is already set"
        );
        
        addressIco = _addressIco;

        uint256 amountToSell = RESERVED_TOKENS_FOR_PRE_ICO.add(RESERVED_TOKENS_FOR_ICO).add(RESERVED_TOKENS_FOR_ICO_BONUSES);
        balances[addressIco] = amountToSell;
        totalSupply_ = totalSupply_.add(amountToSell);
        emit Transfer(address(0), addressIco, amountToSell);

        isIcoSet = true;        
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value, this,
                _extraData);
            return true;
        }
    }

}