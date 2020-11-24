 

pragma solidity ^0.4.13;

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

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64  ) public constant returns (uint256) {
    return balanceOf(holder);
  }
}

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
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

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract HasNoEther is Ownable {

   
  function HasNoEther() payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address  , uint256  , bytes  ) external {
    revert();
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

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
      require(_value == 0 || allowed[msg.sender][_spender] == 0);
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

contract RegulatedToken is StandardToken, PausableToken, LimitedTransferToken, HasNoEther, HasNoTokens {

    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    uint256 constant MAX_LOCKS_PER_ADDRESS = 20;

    enum RedeemReason{RegulatoryRedemption, Buyback, Other}
    enum LockReason{PreICO, Vesting, USPerson, FundOriginated, Other}

    struct TokenLock {
        uint64 id;
        LockReason reason;
        uint256 value;
        uint64 autoReleaseTime;        
    }

    struct TokenRedemption {
        uint64 redemptionId;
        RedeemReason reason;
        uint256 value;
    }

    uint256 public totalInactive;
    uint64 private lockCounter = 1;

     
    mapping(address => bool) private admins;

     
    mapping(address => TokenLock[]) private locks;

     
    mapping(address => bool) private burnWallets;

     
    mapping(address => TokenRedemption[]) private tokenRedemptions;

    event Issued(address indexed to, uint256 value, uint256 valueLocked);
    event Locked(address indexed who, uint256 value, LockReason reason, uint releaseTime, uint64 lockId);
    event Unlocked(address indexed who, uint256 value, uint64 lockId);
    event AddedBurnWallet(address indexed burnWallet);
    event Redeemed(address indexed from, address indexed burnWallet, uint256 value, RedeemReason reason, uint64 indexed redemptionId);
    event Burned(address indexed burnWallet, uint256 value);
    event Destroyed();
    event AdminAdded(address admin);
    event AdminRemoved(address admin);



     
    function destroy() onlyOwner public {
        require(totalSupply == 0);
        Destroyed();
        selfdestruct(owner);
    }

     

    function addAdmin(address _address) onlyOwner public{
        admins[_address] = true;
        AdminAdded(_address);
    }

    function removeAdmin(address _address) onlyOwner public{
        admins[_address] = false;
        AdminRemoved(_address);
    }
     
    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender] == true);
        _;
    }


     


     

    function issueTokens(address _to, uint256 _value) onlyAdmin public returns (bool){
        issueTokensWithLocking(_to, _value, 0, LockReason.Other, 0);
    }

     
    function issueTokensWithLocking(address _to, uint256 _value, uint256 _valueLocked, LockReason _why, uint64 _releaseTime) onlyAdmin public returns (bool){

         
        require(_to != address(0));
        require(_value > 0);
        require(_valueLocked >= 0 && _valueLocked <= _value);

         
        require(totalInactive >= _value);

         
        totalSupply = totalSupply.add(_value);
        totalInactive = totalInactive.sub(_value);
        balances[_to] = balances[_to].add(_value);

        Issued(_to, _value, _valueLocked);
        Transfer(0x0, _to, _value);

        if (_valueLocked > 0) {
            lockTokens(_to, _valueLocked, _why, _releaseTime);
        }
    }



     


     
    function lockTokens(address _who, uint _value, LockReason _reason, uint64 _releaseTime) onlyAdmin public returns (uint64){
        require(_who != address(0));
        require(_value > 0);
        require(_releaseTime == 0 || _releaseTime > uint64(now));
         
        require(locks[_who].length < MAX_LOCKS_PER_ADDRESS);

        uint64 lockId = lockCounter++;

         
        locks[_who].push(TokenLock(lockId, _reason, _value, _releaseTime));
        Locked(_who, _value, _reason, _releaseTime, lockId);

        return lockId;
    }

     
    function unlockTokens(address _who, uint64 _lockId) onlyAdmin public returns (bool) {
        require(_who != address(0));
        require(_lockId > 0);

        for (uint8 i = 0; i < locks[_who].length; i++) {
            if (locks[_who][i].id == _lockId) {
                Unlocked(_who, locks[_who][i].value, _lockId);
                delete locks[_who][i];
                locks[_who][i] = locks[_who][locks[_who].length.sub(1)];
                locks[_who].length -= 1;

                return true;
            }
        }
        return false;
    }

     
    function lockCount(address _who) public constant returns (uint8){
        require(_who != address(0));
        return uint8(locks[_who].length);
    }

     
    function lockInfo(address _who, uint64 _index) public constant returns (uint64 id, uint8 reason, uint value, uint64 autoReleaseTime){
        require(_who != address(0));
        require(_index < locks[_who].length);
        id = locks[_who][_index].id;
        reason = uint8(locks[_who][_index].reason);
        value = locks[_who][_index].value;
        autoReleaseTime = locks[_who][_index].autoReleaseTime;
    }

     
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(time > 0);

         
        if (isBurnWallet(holder)){
            return 0;
        }

        uint8 holderLockCount = uint8(locks[holder].length);

         
        if (holderLockCount == 0) return super.transferableTokens(holder, time);

        uint256 totalLockedTokens = 0;
        for (uint8 i = 0; i < holderLockCount; i ++) {

            if (locks[holder][i].autoReleaseTime == 0 || locks[holder][i].autoReleaseTime > time) {
                totalLockedTokens = SafeMath.add(totalLockedTokens, locks[holder][i].value);
            }
        }
        uint balanceOfHolder = balanceOf(holder);

         
        uint256 transferable = SafeMath.sub(balanceOfHolder, Math.min256(totalLockedTokens, balanceOfHolder));

         
        return Math.min256(transferable, super.transferableTokens(holder, time));
    }

     


     
    function addBurnWallet(address _burnWalletAddress) onlyAdmin {
        require(_burnWalletAddress != address(0));
        burnWallets[_burnWalletAddress] = true;
        AddedBurnWallet(_burnWalletAddress);
    }

     
    function redeemTokens(address _from, address _burnWallet, uint256 _value, RedeemReason _reason, uint64 _redemptionId) onlyAdmin {
        require(_from != address(0));
        require(_redemptionId > 0);
        require(isBurnWallet(_burnWallet));
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_burnWallet] = balances[_burnWallet].add(_value);
        tokenRedemptions[_from].push(TokenRedemption(_redemptionId, _reason, _value));
        Transfer(_from, _burnWallet, _value);
        Redeemed(_from, _burnWallet, _value, _reason, _redemptionId);
    }

     
    function burnTokens(address _burnWallet, uint256 _value) onlyAdmin {
        require(_value > 0);
        require(isBurnWallet(_burnWallet));
        require(balances[_burnWallet] >= _value);
        balances[_burnWallet] = balances[_burnWallet].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burned(_burnWallet, _value);
        Transfer(_burnWallet,0x0,_value);
    }

     
    function isBurnWallet(address _burnWalletAddress) constant public returns (bool){
        return burnWallets[_burnWalletAddress];
    }

     
    function redemptionCount(address _who) public constant returns (uint64){
        require(_who != address(0));
        return uint64(tokenRedemptions[_who].length);
    }

     
    function redemptionInfo(address _who, uint64 _index) public constant returns (uint64 redemptionId, uint8 reason, uint value){
        require(_who != address(0));
        require(_index < tokenRedemptions[_who].length);
        redemptionId = tokenRedemptions[_who][_index].redemptionId;
        reason = uint8(tokenRedemptions[_who][_index].reason);
        value = tokenRedemptions[_who][_index].value;
    }

     

    function totalRedemptionIdValue(address _who, uint64 _redemptionId) public constant returns (uint256){
        require(_who != address(0));
        uint256 total = 0;
        uint64 numberOfRedemptions = redemptionCount(_who);
        for (uint64 i = 0; i < numberOfRedemptions; i++) {
            if (tokenRedemptions[_who][i].redemptionId == _redemptionId) {
                total = SafeMath.add(total, tokenRedemptions[_who][i].value);
            }
        }
        return total;
    }

}

contract SpiceToken is RegulatedToken {

    string public constant name = "SPiCE VC Token";
    string public constant symbol = "SPICE";
    uint8 public constant decimals = 8;
    uint256 private constant INITIAL_INACTIVE_TOKENS = 130 * 1000000 * (10 ** uint256(decimals));   


    function SpiceToken() RegulatedToken() {
        totalInactive = INITIAL_INACTIVE_TOKENS;
        totalSupply = 0;
    }

}