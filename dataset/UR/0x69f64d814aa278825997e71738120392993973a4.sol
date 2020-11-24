 

pragma solidity ^0.4.24;


 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
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

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function increaseApproval(address _spender, uint _addedValue) external onlyPayloadSize(2 * 32) returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) external onlyPayloadSize(2 * 32) returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
    } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract Owners {

  mapping (address => bool) public owners;
  uint public ownersCount;
  uint public minOwnersRequired = 2;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

   
  constructor(bool withDeployer) public {
    if (withDeployer) {
      ownersCount++;
      owners[msg.sender] = true;
    }
    owners[0x23B599A0949C6147E05C267909C16506C7eFF229] = true;
    owners[0x286A70B3E938FCa244208a78B1823938E8e5C174] = true;
    ownersCount = ownersCount + 2;
  }

   
  function addOwner(address _address) public ownerOnly {
    require(_address != address(0));
    owners[_address] = true;
    ownersCount++;
    emit OwnerAdded(_address);
  }

   
  function removeOwner(address _address) public ownerOnly notOwnerItself(_address) minOwners {
    require(owners[_address] == true);
    owners[_address] = false;
    ownersCount--;
    emit OwnerRemoved(_address);
  }

   
  modifier ownerOnly {
    require(owners[msg.sender]);
    _;
  }

  modifier notOwnerItself(address _owner) {
    require(msg.sender != _owner);
    _;
  }

  modifier minOwners {
    require(ownersCount > minOwnersRequired);
    _;
  }

}

 
contract MintableToken is StandardToken, Owners(true) {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintStarted();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) external ownerOnly canMint onlyPayloadSize(2 * 32) returns (bool) {
    return internalMint(_to, _amount);
  }

   
  function finishMinting() public ownerOnly canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

   
  function startMinting() public ownerOnly returns (bool) {
    mintingFinished = false;
    emit MintStarted();
    return true;
  }

  function internalMint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
}

contract REIDAOMintableToken is MintableToken {

  uint public decimals = 8;

  bool public tradingStarted = false;

   
  function transfer(address _to, uint _value) public canTrade returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) public canTrade returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  modifier canTrade() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() public ownerOnly {
    tradingStarted = true;
  }
}

contract REIDAOMintableLockableToken is REIDAOMintableToken {

  struct TokenLock {
    uint256 value;
    uint lockedUntil;
  }

  mapping (address => TokenLock[]) public locks;

   
  function transfer(address _to, uint _value) public canTransfer(msg.sender, _value) returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint _value) public canTransfer(msg.sender, _value) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function lockTokens(address _to, uint256 _value, uint256 _lockUntil) public ownerOnly {
    require(_value <= balanceOf(_to));
    require(_lockUntil > now);
    locks[_to].push(TokenLock(_value, _lockUntil));
  }

   
  function mintAndLockTokens(address _to, uint256 _value, uint256 _lockUntil) public ownerOnly {
    require(_lockUntil > now);
    internalMint(_to, _value);
    lockTokens(_to, _value, _lockUntil);
  }

   
  function transferableTokens(address _holder) public constant returns (uint256) {
    uint256 lockedTokens = getLockedTokens(_holder);
    return balanceOf(_holder).sub(lockedTokens);
  }

   
  function getLockedTokens(address _holder) public constant returns (uint256) {
    uint256 numLocks = getTokenLocksCount(_holder);

     
    uint256 lockedTokens = 0;
    for (uint256 i = 0; i < numLocks; i++) {
      if (locks[_holder][i].lockedUntil >= now) {
        lockedTokens = lockedTokens.add(locks[_holder][i].value);
      }
    }

    return lockedTokens;
  }

   
  function getTokenLocksCount(address _holder) internal constant returns (uint256 index) {
    return locks[_holder].length;
  }

   
  modifier canTransfer(address _sender, uint256 _value) {
    uint256 transferableTokensAmt = transferableTokens(_sender);
    require(_value <= transferableTokensAmt);
     
    if (transferableTokensAmt == balanceOf(_sender) && getTokenLocksCount(_sender) > 0) {
      delete locks[_sender];
    }
    _;
  }
}

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract REIDAOBurnableToken is BurnableToken {

  mapping (address => bool) public hostedWallets;

   
  function burn(uint256 _value) public hostedWalletsOnly {
    return super.burn(_value);
  }

   
  function addHostedWallet(address _wallet) public {
    hostedWallets[_wallet] = true;
  }

   
  function removeHostedWallet(address _wallet) public {
    hostedWallets[_wallet] = false;
  }

   
  modifier hostedWalletsOnly {
    require(hostedWallets[msg.sender] == true);
    _;
  }
}

contract REIDAOMintableBurnableLockableToken is REIDAOMintableLockableToken, REIDAOBurnableToken {

   
  function addHostedWallet(address _wallet) public ownerOnly {
    return super.addHostedWallet(_wallet);
  }

   
  function removeHostedWallet(address _wallet) public ownerOnly {
    return super.removeHostedWallet(_wallet);
  }

   
  function burn(uint256 _value) public canTransfer(msg.sender, _value) {
    return super.burn(_value);
  }
}

contract CRVToken is REIDAOMintableBurnableLockableToken {
  string public name = "Crowdvilla Ownership";
  string public symbol = "CRV";
}