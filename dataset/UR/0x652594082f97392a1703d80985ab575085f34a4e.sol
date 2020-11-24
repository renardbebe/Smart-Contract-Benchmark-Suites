 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.24;



 
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
    return _mint(_to, _amount);
  }

    
  function _mint(
    address _to,
    uint256 _amount
  ) 
    internal
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

 

pragma solidity ^0.4.24;



 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

pragma solidity ^0.4.24;



 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

pragma solidity ^0.4.24;



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

pragma solidity ^0.4.24;




 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

pragma solidity ^0.4.24;


 

library ECRecovery {

   
  function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (_sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(_hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}

 

pragma solidity ^0.4.24;








interface ASilverDollar {
  function purchaseWithSilverToken(address, uint256) external returns(bool);
}

contract SilverToken is Destructible, Pausable, MintableToken, BurnableToken, DetailedERC20("Silvertoken", "SLVT", 8), Whitelist {
  using SafeMath for uint256;
  using ECRecovery for bytes32;

  uint256 public transferFee = 10; 
  uint256 public transferDiscountFee = 8; 
  uint256 public redemptionFee = 40; 
  uint256 public convertFee = 10; 
  address public feeReturnAddress = 0xE34f13B2dadC938f44eCbC38A8dBe94B8bdB2109;
  uint256 public transferFreeAmount;
  uint256 public transferDiscountAmount;
  address public silverDollarAddress;
  address public SLVTReserve = 0x900122447a2Eaeb1655C99A91E20f506D509711B;
  bool    public canPurchase = true;
  bool    public canConvert = true;

   

  uint256 internal multiplier;
  uint256 internal percentage = 1000;

   
  event TokenRedeemed(address from, uint256 amount);
   
  event TokenPurchased(address addr, uint256 amount, uint256 tokens);
   
  event FeeApplied(string name, address addr, uint256 amount);
  event Converted(address indexed sender, uint256 amountSLVT, uint256 amountSLVD, uint256 amountFee);

  modifier purchasable() {
    require(canPurchase == true, "can't purchase");
    _;
  }

  modifier onlySilverDollar() {
    require(msg.sender == silverDollarAddress, "not silverDollar");
    _;
  }
  
  modifier isConvertible() {
    require(canConvert == true, "SLVT conversion disabled");
    _;
  }


  constructor () public {
    multiplier = 10 ** uint256(decimals);
    transferFreeAmount = 2 * multiplier;
    transferDiscountAmount = 500 * multiplier;
    owner = msg.sender;
    super.mint(msg.sender, 1 * 1000 * 1000 * multiplier);
  }

   

  function setTransferFreeAmount(uint256 value) public onlyOwner      { transferFreeAmount = value; }
  function setTransferDiscountAmount(uint256 value) public onlyOwner  { transferDiscountAmount = value; }
  function setRedemptionFee(uint256 value) public onlyOwner           { redemptionFee = value; }
  function setFeeReturnAddress(address value) public onlyOwner        { feeReturnAddress = value; }
  function setCanPurchase(bool value) public onlyOwner                { canPurchase = value; }
  function setSilverDollarAddress(address value) public onlyOwner     { silverDollarAddress = value; }
  function setCanConvert(bool value) public onlyOwner                 { canConvert = value; }
  function setConvertFee(uint256 value) public onlyOwner              { convertFee = value; }


  function increaseTotalSupply(uint256 value) public onlyOwner returns (uint256) {
    super.mint(owner, value);
    return totalSupply_;
  }

   

   

  function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 feesPaid = payFees(address(0), to, amount);
    require(super.transfer(to, amount.sub(feesPaid)), "failed transfer");

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 feesPaid = payFees(from, to, amount);
    require(super.transferFrom(from, to, amount.sub(feesPaid)), "failed transferFrom");

    return true;
  }

   

   

  function payFees(address from, address to, uint256 amount) private returns (uint256 fees) {
    if (msg.sender == owner || hasRole(from, ROLE_WHITELISTED) || hasRole(msg.sender, ROLE_WHITELISTED) || hasRole(to, ROLE_WHITELISTED))
        return 0;
    fees = getTransferFee(amount);
    if (from == address(0)) {
      require(super.transfer(feeReturnAddress, fees), "transfer fee payment failed");
    }
    else {
      require(super.transferFrom(from, feeReturnAddress, fees), "transferFrom fee payment failed");
    }
    emit FeeApplied("Transfer", to, fees);
  }

  function getTransferFee(uint256 amount) internal view returns(uint256) {
    if (transferFreeAmount > 0 && amount <= transferFreeAmount) return 0;
    if (transferDiscountAmount > 0 && amount >= transferDiscountAmount) return amount.mul(transferDiscountFee).div(percentage);
    return amount.mul(transferFee).div(percentage);
  }

  function transferTokens(address from, address to, uint256 amount) internal returns (bool) {
    require(balances[from] >= amount, "balance insufficient");

    balances[from] = balances[from].sub(amount);
    balances[to] = balances[to].add(amount);

    emit Transfer(from, to, amount);

    return true;
  }

  function purchase(uint256 tokens, uint256 fee, uint256 timestamp, bytes signature) public payable purchasable whenNotPaused {
    require(
      isSignatureValid(
        msg.sender, msg.value, tokens, fee, timestamp, signature
      ),
      "invalid signature"
    );
    require(tokens > 0, "invalid number of tokens");
    
    emit TokenPurchased(msg.sender, msg.value, tokens);
    transferTokens(owner, msg.sender, tokens);

    feeReturnAddress.transfer(msg.value);
    if (fee > 0) {
      emit FeeApplied("Purchase", msg.sender, fee);
    }       
  }

  function purchasedSilverDollar(uint256 amount) public onlySilverDollar purchasable whenNotPaused returns (bool) {
    require(super._mint(SLVTReserve, amount), "minting of slvT failed");
    
    return true;
  }

  function purchaseWithSilverDollar(address to, uint256 amount) public onlySilverDollar purchasable whenNotPaused returns (bool) {
    require(transferTokens(SLVTReserve, to, amount), "failed transfer of slvT from reserve");

    return true;
  }

  function redeem(uint256 tokens) public whenNotPaused {
    require(tokens > 0, "amount of tokens redeemed must be > 0");

    uint256 fee = tokens.mul(redemptionFee).div(percentage);

    _burn(msg.sender, tokens.sub(fee));
    if (fee > 0) {
      require(super.transfer(feeReturnAddress, fee), "token transfer failed");
      emit FeeApplied("Redeem", msg.sender, fee);
    }
    emit TokenRedeemed(msg.sender, tokens);
  }

  function isSignatureValid(
    address sender, uint256 amount, uint256 tokens, 
    uint256 fee, uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender, 
        amount, 
        tokens,
        fee,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }

  function isConvertSignatureValid(
    address sender, uint256 amountSLVT, uint256 amountSLVD, 
    uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender, 
        amountSLVT, 
        amountSLVD,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }

  function convertToSLVD(
    uint256 amountSLVT, uint256 amountSLVD,
    uint256 timestamp, bytes signature
  ) public isConvertible whenNotPaused returns (bool) {
    require(
      isConvertSignatureValid(
        msg.sender, amountSLVT, 
        amountSLVD, timestamp, signature
      ), 
      "convert failed, invalid signature"
    );

    uint256 fees = amountSLVT.mul(convertFee).div(percentage);
    if (whitelist(msg.sender) && Whitelist(silverDollarAddress).whitelist(msg.sender))
      fees = 0;

    super.transfer(SLVTReserve, amountSLVT.sub(fees));
    require(super.transfer(feeReturnAddress, fees), "transfer fee payment failed");
    require(
      ASilverDollar(silverDollarAddress).purchaseWithSilverToken(msg.sender, amountSLVD), 
      "failed purchase of silverdollar with silvertoken"
    );
    
    emit Converted(msg.sender, amountSLVD, amountSLVD, fees);
    return true;
  }
}