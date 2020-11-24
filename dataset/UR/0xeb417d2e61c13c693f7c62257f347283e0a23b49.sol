 

pragma solidity 0.4.25;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
 
contract PumaPayToken is MintableToken {

    string public name = "PumaPay"; 
    string public symbol = "PMA";
    uint8 public decimals = 18;

    constructor() public {
    }

     
    modifier whenNotMinting() {
        require(mintingFinished);
        _;
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public whenNotMinting returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotMinting returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

 
 
contract PumaPayPullPayment is Ownable {

    using SafeMath for uint256;

     
     
     

    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogPaymentRegistered(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogPaymentCancelled(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogPullPaymentExecuted(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogSetExchangeRate(string currency, uint256 exchangeRate);

     
     
     

    uint256 constant private DECIMAL_FIXER = 10 ** 10;     
    uint256 constant private FIAT_TO_CENT_FIXER = 100;     
    uint256 constant private ONE_ETHER = 1 ether;          
    uint256 constant private MINIMUM_AMOUNT_OF_ETH_FOR_OPARATORS = 0.01 ether;  
    uint256 constant private OVERFLOW_LIMITER_NUMBER = 10 ** 20;  

     
     
     

    PumaPayToken public token;

    mapping(string => uint256) private exchangeRates;
    mapping(address => bool) public executors;
    mapping(address => mapping(address => PullPayment)) public pullPayments;

    struct PullPayment {
        string merchantID;                       
        string paymentID;                        
        string currency;                         
        uint256 initialPaymentAmountInCents;     
        uint256 fiatAmountInCents;               
        uint256 frequency;                       
        uint256 numberOfPayments;                
        uint256 startTimestamp;                  
        uint256 nextPaymentTimestamp;            
        uint256 lastPaymentTimestamp;            
        uint256 cancelTimestamp;                 
    }

     
     
     
    modifier isExecutor() {
        require(executors[msg.sender]);
        _;
    }

    modifier executorExists(address _executor) {
        require(executors[_executor]);
        _;
    }

    modifier executorDoesNotExists(address _executor) {
        require(!executors[_executor]);
        _;
    }

    modifier paymentExists(address _client, address _beneficiary) {
        require(doesPaymentExist(_client, _beneficiary));
        _;
    }

    modifier paymentNotCancelled(address _client, address _beneficiary) {
        require(pullPayments[_client][_beneficiary].cancelTimestamp == 0);
        _;
    }

    modifier isValidPullPaymentRequest(address _client, address _beneficiary, string _paymentID) {
        require(
            (pullPayments[_client][_beneficiary].initialPaymentAmountInCents > 0 ||
            (now >= pullPayments[_client][_beneficiary].startTimestamp &&
            now >= pullPayments[_client][_beneficiary].nextPaymentTimestamp)
            )
            &&
            pullPayments[_client][_beneficiary].numberOfPayments > 0 &&
        (pullPayments[_client][_beneficiary].cancelTimestamp == 0 ||
        pullPayments[_client][_beneficiary].cancelTimestamp > pullPayments[_client][_beneficiary].nextPaymentTimestamp) &&
        keccak256(
            abi.encodePacked(pullPayments[_client][_beneficiary].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID))
        );
        _;
    }

    modifier isValidDeletionRequest(string paymentID, address client, address beneficiary) {
        require(
            beneficiary != address(0) &&
            client != address(0) &&
            bytes(paymentID).length != 0
        );
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
     
     

     
     
    constructor (PumaPayToken _token)
    public
    {
        require(_token != address(0));
        token = _token;
    }

     
    function() external payable {
    }

     
     
     

     
     
     
     
    function addExecutor(address _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorDoesNotExists(_executor)
    {
        _executor.transfer(0.25 ether);
        executors[_executor] = true;

        if (isFundingNeeded(owner)) {
            owner.transfer(0.5 ether);
        }

        emit LogExecutorAdded(_executor);
    }

     
     
     
    function removeExecutor(address _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;
        if (isFundingNeeded(owner)) {
            owner.transfer(0.5 ether);
        }
        emit LogExecutorRemoved(_executor);
    }

     
     
     
     
     
    function setRate(string _currency, uint256 _rate)
    public
    onlyOwner
    returns (bool) {
        exchangeRates[_currency] = _rate;
        emit LogSetExchangeRate(_currency, _rate);

        if (isFundingNeeded(owner)) {
            owner.transfer(0.5 ether);
        }

        return true;
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _merchantID,
        string _paymentID,
        address _client,
        address _beneficiary,
        string _currency,
        uint256 _initialPaymentAmountInCents,
        uint256 _fiatAmountInCents,
        uint256 _frequency,
        uint256 _numberOfPayments,
        uint256 _startTimestamp
    )
    public
    isExecutor()
    {
        require(
            bytes(_paymentID).length > 0 &&
            bytes(_currency).length > 0 &&
            _client != address(0) &&
            _beneficiary != address(0) &&
            _fiatAmountInCents > 0 &&
            _frequency > 0 &&
            _frequency < OVERFLOW_LIMITER_NUMBER &&
            _numberOfPayments > 0 &&
            _startTimestamp > 0 &&
            _startTimestamp < OVERFLOW_LIMITER_NUMBER
        );

        pullPayments[_client][_beneficiary].currency = _currency;
        pullPayments[_client][_beneficiary].initialPaymentAmountInCents = _initialPaymentAmountInCents;
        pullPayments[_client][_beneficiary].fiatAmountInCents = _fiatAmountInCents;
        pullPayments[_client][_beneficiary].frequency = _frequency;
        pullPayments[_client][_beneficiary].startTimestamp = _startTimestamp;
        pullPayments[_client][_beneficiary].numberOfPayments = _numberOfPayments;

        require(isValidRegistration(v, r, s, _client, _beneficiary, pullPayments[_client][_beneficiary]));

        pullPayments[_client][_beneficiary].merchantID = _merchantID;
        pullPayments[_client][_beneficiary].paymentID = _paymentID;
        pullPayments[_client][_beneficiary].nextPaymentTimestamp = _startTimestamp;
        pullPayments[_client][_beneficiary].lastPaymentTimestamp = 0;
        pullPayments[_client][_beneficiary].cancelTimestamp = 0;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(0.5 ether);
        }

        emit LogPaymentRegistered(_client, _beneficiary, _paymentID);
    }

     
     
     
     
     
     
     
     
     
     
     
    function deletePullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _paymentID,
        address _client,
        address _beneficiary
    )
    public
    isExecutor()
    paymentExists(_client, _beneficiary)
    paymentNotCancelled(_client, _beneficiary)
    isValidDeletionRequest(_paymentID, _client, _beneficiary)
    {
        require(isValidDeletion(v, r, s, _paymentID, _client, _beneficiary));

        pullPayments[_client][_beneficiary].cancelTimestamp = now;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(0.5 ether);
        }

        emit LogPaymentCancelled(_client, _beneficiary, _paymentID);
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function executePullPayment(address _client, string _paymentID)
    public
    paymentExists(_client, msg.sender)
    isValidPullPaymentRequest(_client, msg.sender, _paymentID)
    {
        uint256 amountInPMA;
        if (pullPayments[_client][msg.sender].initialPaymentAmountInCents > 0) {
            amountInPMA = calculatePMAFromFiat(pullPayments[_client][msg.sender].initialPaymentAmountInCents, pullPayments[_client][msg.sender].currency);
            pullPayments[_client][msg.sender].initialPaymentAmountInCents = 0;
        } else {
            amountInPMA = calculatePMAFromFiat(pullPayments[_client][msg.sender].fiatAmountInCents, pullPayments[_client][msg.sender].currency);

            pullPayments[_client][msg.sender].nextPaymentTimestamp = pullPayments[_client][msg.sender].nextPaymentTimestamp + pullPayments[_client][msg.sender].frequency;
            pullPayments[_client][msg.sender].numberOfPayments = pullPayments[_client][msg.sender].numberOfPayments - 1;
        }
        pullPayments[_client][msg.sender].lastPaymentTimestamp = now;
        token.transferFrom(_client, msg.sender, amountInPMA);

        emit LogPullPaymentExecuted(_client, msg.sender, pullPayments[_client][msg.sender].paymentID);
    }

    function getRate(string _currency) public view returns (uint256) {
        return exchangeRates[_currency];
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculatePMAFromFiat(uint256 _fiatAmountInCents, string _currency)
    internal
    view
    returns (uint256) {
        return ONE_ETHER.mul(DECIMAL_FIXER).mul(_fiatAmountInCents).div(exchangeRates[_currency]).div(FIAT_TO_CENT_FIXER);
    }

     
     
     
     
     
     
     
     
     
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _client,
        address _beneficiary,
        PullPayment _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _beneficiary,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp
                )
            ),
            v, r, s) == _client;
    }

     
     
     
     
     
     
     
     
     
    function isValidDeletion(
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _paymentID,
        address _client,
        address _beneficiary
    )
    internal
    view
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _paymentID,
                    _beneficiary
                )
            ), v, r, s) == _client
        && keccak256(
            abi.encodePacked(pullPayments[_client][_beneficiary].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID));
    }

     
     
     
     
    function doesPaymentExist(address _client, address _beneficiary)
    internal
    view
    returns (bool) {
        return (
        bytes(pullPayments[_client][_beneficiary].currency).length > 0 &&
        pullPayments[_client][_beneficiary].fiatAmountInCents > 0 &&
        pullPayments[_client][_beneficiary].frequency > 0 &&
        pullPayments[_client][_beneficiary].startTimestamp > 0 &&
        pullPayments[_client][_beneficiary].numberOfPayments > 0 &&
        pullPayments[_client][_beneficiary].nextPaymentTimestamp > 0
        );
    }

     
     
     
     
    function isFundingNeeded(address _address)
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPARATORS;
    }
}