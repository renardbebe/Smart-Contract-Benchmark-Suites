 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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

 

contract WLO is StandardBurnableToken, Ownable {

  string public name = "Wollo";
  string public symbol = "WLO";

  uint8 public decimals = 18;
  uint public INITIAL_SUPPLY = 25000000 * uint(10**uint(decimals));

  constructor () public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

 

contract ICOEngineInterface {

   
  function started() public view returns(bool);

   
  function ended() public view returns(bool);

   
  function startTime() public view returns(uint);

   
  function endTime() public view returns(uint);

   
   
   

   
   
   

   
  function totalTokens() public view returns(uint);

   
   
  function remainingTokens() public view returns(uint);

   
  function price() public view returns(uint);
}

 

 
contract KYCBase {
  using SafeMath for uint256;

  mapping (address => bool) public isKycSigner;
  mapping (uint64 => uint256) public alreadyPayed;

  event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

  constructor(address[] kycSigners) internal {
    for (uint i = 0; i < kycSigners.length; i++) {
      isKycSigner[kycSigners[i]] = true;
    }
  }

   
  function releaseTokensTo(address buyer) internal returns(bool);

   
  function senderAllowedFor(address buyer) internal view returns(bool) {
    return buyer == msg.sender;
  }

  function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s) public payable returns (bool) {
    require(senderAllowedFor(buyerAddress));
    return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
  }

  function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s) public payable returns (bool) {
    return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
  }

  function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s) private returns (bool) {
     
    bytes32 hash = sha256(abi.encodePacked("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount));
    address signer = ecrecover(hash, v, r, s);
    if (!isKycSigner[signer]) {
      revert();
    } else {
      uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
      require(totalPayed <= maxAmount);
      alreadyPayed[buyerId] = totalPayed;
      emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
      return releaseTokensTo(buyerAddress);
    }
  }

   
  function () public {
    revert();
  }
}

 

 
pragma solidity ^0.4.24;





contract WolloCrowdsale is ICOEngineInterface, KYCBase {
  using SafeMath for uint;

  WLO public token;
  address public wallet;
  uint public price;
  uint public startTime;
  uint public endTime;
  uint public cap;
  uint public remainingTokens;
  uint public totalTokens;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  event SentBack(address indexed purchaser, uint256 amount);

   
  event Log(string name, uint number);
  event LogBool(string name, bool log);
  event LogS(string name, string log);
  event LogA(string name, address log);

   
  constructor (
    address[] kycSigner,
    address _token,
    address _wallet,
    uint _startTime,
    uint _endTime,
    uint _price,
    uint _cap
  ) public KYCBase(kycSigner) {

    require(_token != address(0));
    require(_wallet != address(0));
     
    require(_endTime > _startTime);
    require(_price > 0);
    require(_cap > 0);

    token = WLO(_token);

    wallet = _wallet;
    startTime = _startTime;
    endTime = _endTime;
    price = _price;
    cap = _cap;

    totalTokens = cap;
    remainingTokens = cap;
  }

   
  function releaseTokensTo(address buyer) internal returns(bool) {

    emit LogBool("started", started());
    emit LogBool("ended", ended());

    require(started() && !ended());

    emit Log("wei", msg.value);
    emit LogA("buyer", buyer);

    uint weiAmount = msg.value;
    uint weiBack = 0;
    uint tokens = weiAmount.mul(price);
    uint tokenRaised = totalTokens - remainingTokens;

    if (tokenRaised.add(tokens) > cap) {
      tokens = cap.sub(tokenRaised);
      weiAmount = tokens.div(price);
      weiBack = msg.value - weiAmount;
    }

    emit Log("tokens", tokens);

    remainingTokens = remainingTokens.sub(tokens);

    require(token.transferFrom(wallet, buyer, tokens));
    wallet.transfer(weiAmount);

    if (weiBack > 0) {
      msg.sender.transfer(weiBack);
      emit SentBack(msg.sender, weiBack);
    }

    emit TokenPurchase(msg.sender, buyer, weiAmount, tokens);
    return true;
  }

  function started() public view returns(bool) {
    return now >= startTime;
  }

  function ended() public view returns(bool) {
    return now >= endTime || remainingTokens == 0;
  }

  function startTime() public view returns(uint) {
    return(startTime);
  }

  function endTime() public view returns(uint){
    return(endTime);
  }

  function totalTokens() public view returns(uint){
    return(totalTokens);
  }

  function remainingTokens() public view returns(uint){
    return(remainingTokens);
  }

  function price() public view returns(uint){
    return price;
  }
}