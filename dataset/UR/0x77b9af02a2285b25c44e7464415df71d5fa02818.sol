 

pragma solidity ^0.4.21;

 

 
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
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

 

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
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

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.23;




contract CarryToken is PausableToken, CappedToken, BurnableToken {
    string public name = "CarryToken";
    string public symbol = "CRE";
    uint8 public decimals = 18;

     
     
    uint256 constant TOTAL_CAP = 10000000000 * 1000000000000000000;

     
     
     
    function CarryToken() public CappedToken(TOTAL_CAP) {
    }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.23;






 
contract CarryTokenCrowdsale is WhitelistedCrowdsale, CappedCrowdsale, Pausable {
    using SafeMath for uint256;

    uint256 constant maxGasPrice = 40000000000;   

     
    uint256 public individualMinPurchaseWei;
    uint256 public individualMaxCapWei;

    mapping(address => uint256) public contributions;

     
     
     
    function CarryTokenCrowdsale(
        address _wallet,
        CarryToken _token,
        uint256 _rate,
        uint256 _cap,
        uint256 _individualMinPurchaseWei,
        uint256 _individualMaxCapWei
    ) public CappedCrowdsale(_cap) Crowdsale(_rate, _wallet, _token) {
        individualMinPurchaseWei = _individualMinPurchaseWei;
        individualMaxCapWei = _individualMaxCapWei;
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) internal whenNotPaused {
         
        require(tx.gasprice <= maxGasPrice);

        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 contribution = contributions[_beneficiary];
        uint256 contributionAfterPurchase = contribution.add(_weiAmount);

         
         
         
         
        require(contributionAfterPurchase >= individualMinPurchaseWei);

        require(contributionAfterPurchase <= individualMaxCapWei);
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
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.23;





 
contract GradualDeliveryCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    address[] beneficiaries;
    mapping(address => uint256) public refundedDeposits;

    event TokenDelivered(address indexed beneficiary, uint256 tokenAmount);
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

     
    function deliverTokensInRatio(
        uint256 _numerator,
        uint256 _denominator
    ) external onlyOwner {
        _deliverTokensInRatio(
            _numerator,
            _denominator,
            0,
            beneficiaries.length
        );
    }

     
    function deliverTokensInRatioOfRange(
        uint256 _numerator,
        uint256 _denominator,
        uint _startIndex,
        uint _endIndex
    ) external onlyOwner {
        require(_startIndex < _endIndex);
        _deliverTokensInRatio(_numerator, _denominator, _startIndex, _endIndex);
    }

    function _deliverTokensInRatio(
        uint256 _numerator,
        uint256 _denominator,
        uint _startIndex,
        uint _endIndex
    ) internal {
        require(_denominator > 0);
        require(_numerator <= _denominator);
        uint endIndex = _endIndex;
        if (endIndex > beneficiaries.length) {
            endIndex = beneficiaries.length;
        }
        for (uint i = _startIndex; i < endIndex; i = i.add(1)) {
            address beneficiary = beneficiaries[i];
            uint256 balance = balances[beneficiary];
            if (balance > 0) {
                uint256 amount = balance.mul(_numerator).div(_denominator);
                balances[beneficiary] = balance.sub(amount);
                _deliverTokens(beneficiary, amount);
                emit TokenDelivered(beneficiary, amount);
            }
        }
    }

    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAmount > 0) {
            if (balances[_beneficiary] <= 0) {
                beneficiaries.push(_beneficiary);
            }
            balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        }
    }
     
    function depositRefund(address _beneficiary) public payable {
        require(msg.sender == owner || msg.sender == wallet);
        uint256 weiToRefund = msg.value;
        require(weiToRefund <= weiRaised);
        uint256 tokensToRefund = _getTokenAmount(weiToRefund);
        uint256 tokenBalance = balances[_beneficiary];
        require(tokenBalance >= tokensToRefund);
        weiRaised = weiRaised.sub(weiToRefund);
        balances[_beneficiary] = tokenBalance.sub(tokensToRefund);
        refundedDeposits[_beneficiary] = refundedDeposits[_beneficiary].add(
            weiToRefund
        );
        emit RefundDeposited(_beneficiary, tokensToRefund, weiToRefund);
    }

     
    function receiveRefund(address _beneficiary) public {
        require(msg.sender == owner || msg.sender == _beneficiary);
        _transferRefund(_beneficiary, _beneficiary);
    }

     
    function receiveRefundTo(address _beneficiary, address _wallet) public {
        require(msg.sender == _beneficiary);
        _transferRefund(_beneficiary, _wallet);
    }

    function _transferRefund(address _beneficiary, address _wallet) internal {
        uint256 depositedWeiAmount = refundedDeposits[_beneficiary];
        require(depositedWeiAmount > 0);
        refundedDeposits[_beneficiary] = 0;
        _wallet.transfer(depositedWeiAmount);
        emit Refunded(_beneficiary, _wallet, depositedWeiAmount);
    }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.23;



 
contract CarryTokenPresale is CarryTokenCrowdsale, GradualDeliveryCrowdsale {
    using SafeMath for uint256;

     
     
     
    function CarryTokenPresale(
        address _wallet,
        CarryToken _token,
        uint256 _rate,
        uint256 _cap,
        uint256 _individualMinPurchaseWei,
        uint256 _individualMaxCapWei
    ) public CarryTokenCrowdsale(
        _wallet,
        _token,
        _rate,
        _cap,
        _individualMinPurchaseWei,
        _individualMaxCapWei
    ) {
    }

    function _transferRefund(address _beneficiary, address _wallet) internal {
        uint256 depositedWeiAmount = refundedDeposits[_beneficiary];
        super._transferRefund(_beneficiary, _wallet);
        contributions[_beneficiary] = contributions[_beneficiary].sub(
            depositedWeiAmount
        );
    }
}