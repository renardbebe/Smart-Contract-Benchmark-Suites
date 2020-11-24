 

pragma solidity ^0.4.23;


 
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

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
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

contract Administratable is Ownable {
    mapping (address => bool) admins;

    event AdminAdded(address indexed _admin);

    event AdminRemoved(address indexed _admin);

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    function addAdmin(address _addressToAdd) external onlyOwner {
        require(_addressToAdd != address(0));
        admins[_addressToAdd] = true;

        emit AdminAdded(_addressToAdd);
    }

    function removeAdmin(address _addressToRemove) external onlyOwner {
        require(_addressToRemove != address(0));
        admins[_addressToRemove] = false;

        emit AdminRemoved(_addressToRemove);
    }
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ERC865 is ERC20 {

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function revokeSignature(bytes _signature)
    public
    returns (bool);

}

contract StandardToken is ERC20  {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) public balances;

  uint256 _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
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

contract ERC865Token is ERC865, StandardToken {

     
    mapping(bytes => bool) nonces;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event SignatureRevoked(bytes signature, address indexed from);

     
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);

        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

     
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = approvePreSignedHashing(address(this), _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        allowed[from][_spender] = _value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

     
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = increaseApprovalPreSignedHashing(address(this), _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = decreaseApprovalPreSignedHashing(address(this), _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = transferFromPreSignedHashing(address(this), _from, _to, _value, _fee, _nonce);

        address spender = recover(hashedTx, _signature);
        require(spender != address(0));

        nonces[_signature] = true;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][spender] = allowed[_from][spender].sub(_value);

        balances[spender] = balances[spender].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        nonces[_signature] = true;

        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }

     
    function revokeSignature(bytes _signature) public returns (bool) {
        require(!nonces[_signature]);
        nonces[_signature] = true;

        emit SignatureRevoked(_signature, msg.sender);
        return true;
    }


     
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0x48664c16), _token, _to, _value, _fee, _nonce);
    }

     
    function approvePreSignedHashing(
        address _token,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0xf7ac9c2e), _token, _spender, _value, _fee, _nonce);
    }

     
    function increaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0xa45f71ff), _token, _spender, _addedValue, _fee, _nonce);
    }

      
    function decreaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0x59388d78), _token, _spender, _subtractedValue, _fee, _nonce);
    }

     
    function transferFromPreSignedHashing(
        address _token,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0xb7656dc5), _token, _from, _to, _value, _fee, _nonce);
    }

     
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

       
      if (sig.length != 65) {
        return (address(0));
      }

       
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

       
      if (v < 27) {
        v += 27;
      }

       
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }

}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

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
        emit Paused();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpaused();
    }
}

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public tokenWeiSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
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
    tokenWeiSold = tokenWeiSold.add(tokens);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) pure internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) pure internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

   
  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

   
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
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

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

}
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}
contract WhitelistedCrowdsale is Crowdsale, Administratable {

  mapping(address => bool) public whitelist;

   
  event AddedToWhitelist(address indexed _address);

   
  event RemovedFromWhitelist(address indexed _address);


   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyAdmin {
    whitelist[_beneficiary] = true;
    emit AddedToWhitelist(_beneficiary);
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyAdmin {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyAdmin {
    whitelist[_beneficiary] = false;
    emit RemovedFromWhitelist(_beneficiary);
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract PostDeliveryCrowdsale is TimedCrowdsale, Administratable {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
   
  event TokensWithdrawn(address indexed _address, uint256 _amount);

   
  function withdrawTokens(address _beneficiary) public onlyAdmin {
    require(hasClosed());
    uint256 amount = balances[_beneficiary];
    require(amount > 0);
    balances[_beneficiary] = 0;
    _deliverTokens(_beneficiary, amount);
    emit TokensWithdrawn(_beneficiary, amount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

  function getBalance(address _beneficiary) public returns (uint256) {
      return balances[_beneficiary];
  }

}

contract MultiRoundCrowdsale is  Crowdsale, Ownable {

    using SafeMath for uint256;

    struct SaleRound {
        uint256 start;
        uint256 end;
        uint256 rate;
        uint256 roundCap;
        uint256 minPurchase;
    }

    SaleRound seedRound;
    SaleRound presale;
    SaleRound crowdsaleWeek1;
    SaleRound crowdsaleWeek2;
    SaleRound crowdsaleWeek3;
    SaleRound crowdsaleWeek4;

    bool public saleRoundsSet = false;

     
    function setTokenSaleRounds(uint256[5] _seedRound, uint256[5] _presale, uint256[5] _crowdsaleWeek1, uint256[5] _crowdsaleWeek2, uint256[5] _crowdsaleWeek3, uint256[5] _crowdsaleWeek4) external onlyOwner returns (bool) {
         
        require(!saleRoundsSet);

         
        require(_seedRound[0] < _seedRound[1]);
        require(_presale[0] < _presale[1]);
        require(_crowdsaleWeek1[0] < _crowdsaleWeek1[1]);
        require(_crowdsaleWeek2[0] < _crowdsaleWeek2[1]);
        require(_crowdsaleWeek3[0] < _crowdsaleWeek3[1]);
        require(_crowdsaleWeek4[0] < _crowdsaleWeek4[1]);

         
        require(_seedRound[1] < _presale[0]);
        require(_presale[1] < _crowdsaleWeek1[0]);
        require(_crowdsaleWeek1[1] < _crowdsaleWeek2[0]);
        require(_crowdsaleWeek2[1] < _crowdsaleWeek3[0]);
        require(_crowdsaleWeek3[1] < _crowdsaleWeek4[0]);

        seedRound      = SaleRound(_seedRound[0], _seedRound[1], _seedRound[2], _seedRound[3], _seedRound[4]);
        presale        = SaleRound(_presale[0], _presale[1], _presale[2], _presale[3], _presale[4]);
        crowdsaleWeek1 = SaleRound(_crowdsaleWeek1[0], _crowdsaleWeek1[1], _crowdsaleWeek1[2], _crowdsaleWeek1[3], _crowdsaleWeek1[4]);
        crowdsaleWeek2 = SaleRound(_crowdsaleWeek2[0], _crowdsaleWeek2[1], _crowdsaleWeek2[2], _crowdsaleWeek2[3], _crowdsaleWeek2[4]);
        crowdsaleWeek3 = SaleRound(_crowdsaleWeek3[0], _crowdsaleWeek3[1], _crowdsaleWeek3[2], _crowdsaleWeek3[3], _crowdsaleWeek3[4]);
        crowdsaleWeek4 = SaleRound(_crowdsaleWeek4[0], _crowdsaleWeek4[1], _crowdsaleWeek4[2], _crowdsaleWeek4[3], _crowdsaleWeek4[4]);

        saleRoundsSet = true;
        return saleRoundsSet;
    }

    function getCurrentRound() internal view returns (SaleRound) {
        require(saleRoundsSet);

        uint256 currentTime = block.timestamp;
        if (currentTime > seedRound.start && currentTime <= seedRound.end) {
            return seedRound;
        } else if (currentTime > presale.start && currentTime <= presale.end) {
            return presale;
        } else if (currentTime > crowdsaleWeek1.start && currentTime <= crowdsaleWeek1.end) {
            return crowdsaleWeek1;
        } else if (currentTime > crowdsaleWeek2.start && currentTime <= crowdsaleWeek2.end) {
            return crowdsaleWeek2;
        } else if (currentTime > crowdsaleWeek3.start && currentTime <= crowdsaleWeek3.end) {
            return crowdsaleWeek3;
        } else if (currentTime > crowdsaleWeek4.start && currentTime <= crowdsaleWeek4.end) {
            return crowdsaleWeek4;
        } else {
            revert();
        }
    }

    function getCurrentRate() public view returns (uint256) {
        require(saleRoundsSet);
        SaleRound memory currentRound = getCurrentRound();
        return currentRound.rate;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        require(_weiAmount != 0);
        uint256 currentRate = getCurrentRate();
        require(currentRate != 0);

        return currentRate.mul(_weiAmount);
    }
}

contract TipToken is ERC865Token, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 10 ** 9;

    string public constant name = "Tip Token";
    string public constant symbol = "TIP";
    uint8 public constant decimals = 18;

    mapping (address => string) aliases;
    mapping (string => address) addresses;

     
    constructor() public {
        _totalSupply = TOTAL_SUPPLY * (10**uint256(decimals));
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
    function availableSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[owner]).sub(balances[address(0)]);
    }

     
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
    function () public payable {
        revert();
    }

     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
    function setAlias(string alias) public {
        aliases[msg.sender] = alias;
        addresses[alias] = msg.sender;
    }
}

contract TipTokenCrowdsale is MultiRoundCrowdsale, CappedCrowdsale, WhitelistedCrowdsale, AllowanceCrowdsale, PostDeliveryCrowdsale, Pausable {

     
    string public constant name = "Tip Token Crowdsale";


     
    constructor(
        ERC20 _token,
        address _tokenWallet,
        address _vault,
        uint256 _cap,
        uint256 _start, uint256 _end, uint256 _baseRate
        ) public
        Crowdsale(_baseRate, _vault, _token)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_start, _end)
        PostDeliveryCrowdsale()
        WhitelistedCrowdsale()
        AllowanceCrowdsale(_tokenWallet)
        MultiRoundCrowdsale()
        {
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused() {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        SaleRound memory currentRound = getCurrentRound();
        require(weiRaised.add(_weiAmount) <= currentRound.roundCap);
        require(balances[_beneficiary].add(_weiAmount) >= currentRound.minPurchase);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return MultiRoundCrowdsale._getTokenAmount(_weiAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        AllowanceCrowdsale._deliverTokens(_beneficiary, _tokenAmount);
    }
}