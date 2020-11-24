 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.24;




contract CarryToken is PausableToken, CappedToken, BurnableToken {
    string public name = "CarryToken";
    string public symbol = "CRE";
    uint8 public decimals = 18;

     
     
    uint256 constant TOTAL_CAP = 10000000000 * (10 ** uint256(decimals));

    constructor() public CappedToken(TOTAL_CAP) {
    }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.24;





 
contract CarryPublicTokenCrowdsale is CappedCrowdsale, Pausable {
    using SafeMath for uint256;

    uint256 constant maxGasPrice = 40000000000;   

     
    uint256 public individualMinPurchaseWei;

    struct IndividualMaxCap {
        uint256 timestamp;
        uint256 maxWei;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    IndividualMaxCap[] public individualMaxCaps;

    mapping(address => uint256) public contributions;

     
     
     
     
     
     
     
     
     
    uint256[] public whitelistGrades;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    mapping(address => uint8) public whitelist;

     
     
     
    mapping(address => uint256) public balances;

     
     
    bool public withdrawable;

     
     
     
    uint256 public tokenDeliveryDue;

    mapping(address => uint256) public refundedDeposits;

    constructor(
        address _wallet,
        CarryToken _token,
        uint256 _rate,
        uint256 _cap,
        uint256 _tokenDeliveryDue,
        uint256[] _whitelistGrades,
        uint256 _individualMinPurchaseWei,

         
         
         
         
        uint256[] _individualMaxCapTimestamps,
        uint256[] _individualMaxCapWeis
    ) public CappedCrowdsale(_cap) Crowdsale(_rate, _wallet, _token) {
        require(
            _individualMaxCapTimestamps.length == _individualMaxCapWeis.length,
            "_individualMaxCap{Timestamps,Weis} do not have equal length."
        );
        tokenDeliveryDue = _tokenDeliveryDue;
        if (_whitelistGrades.length < 1) {
            whitelistGrades = [0];
        } else {
            require(
                _whitelistGrades.length < 0x100,
                "The grade number must be less than 2^8."
            );
            require(
                _whitelistGrades[0] == 0,
                "The _whitelistGrades[0] must be zero."
            );
            whitelistGrades = _whitelistGrades;
        }
        individualMinPurchaseWei = _individualMinPurchaseWei;
        for (uint i = 0; i < _individualMaxCapTimestamps.length; i++) {
            uint256 timestamp = _individualMaxCapTimestamps[i];
            require(
                i < 1 || timestamp > _individualMaxCapTimestamps[i - 1],
                "_individualMaxCapTimestamps have to be in ascending order and no duplications."
            );
            individualMaxCaps.push(
                IndividualMaxCap(
                    timestamp,
                    _individualMaxCapWeis[i]
                )
            );
        }
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) internal whenNotPaused {
         
        require(
            tx.gasprice <= maxGasPrice,
            "Gas price is too expensive. Don't be competitive."
        );

        super._preValidatePurchase(_beneficiary, _weiAmount);

        uint8 grade = whitelist[_beneficiary];
        require(grade > 0, "Not whitelisted.");
        uint openingTime = whitelistGrades[grade];
        require(
             
            block.timestamp >= openingTime,
            "Currently unavailable to purchase tokens."
        );

        uint256 contribution = contributions[_beneficiary];
        uint256 contributionAfterPurchase = contribution.add(_weiAmount);

         
         
         
         
        require(
            contributionAfterPurchase >= individualMinPurchaseWei,
            "Sent ethers is not enough."
        );

         
        uint256 individualMaxWei = 0;
        for (uint i = 0; i < individualMaxCaps.length; i++) {
            uint256 capTimestamp = individualMaxCaps[i].timestamp;
             
            if (capTimestamp <= block.timestamp) {
                individualMaxWei = individualMaxCaps[i].maxWei;
            } else {
                 
                if (i > 1) {
                    uint offset = i - 1;
                    uint trimmedLength = individualMaxCaps.length - offset;
                    for (uint256 j = 0; j < trimmedLength; j++) {
                        individualMaxCaps[j] = individualMaxCaps[offset + j];
                    }
                    individualMaxCaps.length = trimmedLength;
                }
                break;
            }
        }
        require(
            contributionAfterPurchase <= individualMaxWei,
            individualMaxWei > 0
                ? "Total ethers you've purchased is too much."
                : "Purchase is currently disallowed."
        );
    }

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    ) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount);
        contributions[_beneficiary] = contributions[_beneficiary].add(
            _weiAmount
        );
    }

    function addAddressesToWhitelist(
        address[] _beneficiaries,
        uint8 _grade
    ) external onlyOwner {
        require(_grade < whitelistGrades.length, "No such grade number.");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = _grade;
        }
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    }

    function setWithdrawable(bool _withdrawable) external onlyOwner {
        withdrawable = _withdrawable;
    }

    modifier whenWithdrawable() {
        require(
             
            withdrawable || block.timestamp >= tokenDeliveryDue,
            "Currently tokens cannot be withdrawn."
        );
        _;
    }

    event TokenDelivered(address indexed beneficiary, uint256 tokenAmount);

    function _deliverTokens(address _beneficiary) internal {
        uint256 amount = balances[_beneficiary];
        if (amount > 0) {
            balances[_beneficiary] = 0;
            _deliverTokens(_beneficiary, amount);
            emit TokenDelivered(_beneficiary, amount);
        }
    }

    function withdrawTokens() public whenWithdrawable {
        _deliverTokens(msg.sender);
    }

    function deliverTokens(
        address[] _beneficiaries
    ) public onlyOwner whenWithdrawable {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _deliverTokens(_beneficiaries[i]);
        }
    }

    event RefundDeposited(
        address indexed beneficiary,
        uint256 tokenAmount,
        uint256 weiAmount
    );
    event Refunded(
        address indexed beneficiary,
        address indexed receiver,
        uint256 weiAmount
    );

     
    function depositRefund(address _beneficiary) public payable {
        require(
            msg.sender == owner || msg.sender == wallet,
            "No permission to access."
        );
        uint256 weiToRefund = msg.value;
        require(
            weiToRefund <= weiRaised,
            "Sent ethers is higher than even the total raised ethers."
        );
        uint256 tokensToRefund = _getTokenAmount(weiToRefund);
        uint256 tokenBalance = balances[_beneficiary];
        require(
            tokenBalance >= tokensToRefund,
            "Sent ethers is higher than the ethers _beneficiary has purchased."
        );
        weiRaised = weiRaised.sub(weiToRefund);
        balances[_beneficiary] = tokenBalance.sub(tokensToRefund);
        refundedDeposits[_beneficiary] = refundedDeposits[_beneficiary].add(
            weiToRefund
        );
        emit RefundDeposited(_beneficiary, tokensToRefund, weiToRefund);
    }

     
    function receiveRefund(address _wallet) public {
        _transferRefund(msg.sender, _wallet);
    }

    function _transferRefund(address _beneficiary, address _wallet) internal {
        uint256 depositedWeiAmount = refundedDeposits[_beneficiary];
        require(depositedWeiAmount > 0, "_beneficiary has never purchased.");
        refundedDeposits[_beneficiary] = 0;
        contributions[_beneficiary] = contributions[_beneficiary].sub(
            depositedWeiAmount
        );
        _wallet.transfer(depositedWeiAmount);
        emit Refunded(_beneficiary, _wallet, depositedWeiAmount);
    }
}