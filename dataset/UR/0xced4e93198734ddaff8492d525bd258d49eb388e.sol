 

pragma solidity ^0.4.13;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

contract MintableInterface {
  function mint(address _to, uint256 _amount) returns (bool);
  function mintLocked(address _to, uint256 _amount) returns (bool);
}

 






 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableInterface public token;

   
  uint256 public startBlock;
  uint256 public endBlock;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _wallet) {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_rate > 0);
    require(_wallet != 0x0);

    startBlock = _startBlock;
    endBlock = _endBlock;
    rate = _rate;
    wallet = _wallet;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock && current <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }


}

 
contract TokenCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

   
  uint256 public tokenCap;

  uint256 public soldTokens;

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = soldTokens >= tokenCap;
    return super.hasEnded() || capReached;
  }

   
  function buyTokens(address beneficiary) payable {
     
    uint256 tokens = msg.value.mul(rate);
    uint256 newTotalSold = soldTokens.add(tokens);
    require(newTotalSold <= tokenCap);
    soldTokens = newTotalSold;
    super.buyTokens(beneficiary);
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 





 
contract TokenTimelock {
  
   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint _releaseTime) {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() {
    require(now >= releaseTime);

    uint amount = token.balanceOf(this);
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract EidooToken is MintableInterface, Ownable, StandardToken {
  using SafeMath for uint256;

  string public name = "Eidoo Token";
  string public symbol = "EDO";
  uint256 public decimals = 18;

  uint256 public transferableFromBlock;
  uint256 public lockEndBlock;
  mapping (address => uint256) public initiallyLockedAmount;

  function EidooToken(uint256 _transferableFromBlock, uint256 _lockEndBlock) {
    require(_lockEndBlock > _transferableFromBlock);
    transferableFromBlock = _transferableFromBlock;
    lockEndBlock = _lockEndBlock;
  }

  modifier canTransfer(address _from, uint _value) {
    if (block.number < lockEndBlock) {
      require(block.number >= transferableFromBlock);
      uint256 locked = lockedBalanceOf(_from);
      if (locked > 0) {
        uint256 newBalance = balanceOf(_from).sub(_value);
        require(newBalance >= locked);
      }
    }
   _;
  }

  function lockedBalanceOf(address _to) constant returns(uint256) {
    uint256 locked = initiallyLockedAmount[_to];
    if (block.number >= lockEndBlock ) return 0;
    else if (block.number <= transferableFromBlock) return locked;

    uint256 releaseForBlock = locked.div(lockEndBlock.sub(transferableFromBlock));
    uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
    return locked.sub(released);
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   

  modifier canMint() {
    require(!mintingFinished());
    _;
  }

  function mintingFinished() constant returns(bool) {
    return block.number >= transferableFromBlock;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function mintLocked(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    initiallyLockedAmount[_to] = initiallyLockedAmount[_to].add(_amount);
    return mint(_to, _amount);
  }

  function burn(uint256 _amount) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    Transfer(msg.sender, address(0), _amount);
    return true;
  }
}

contract EidooTokenSale is Ownable, TokenCappedCrowdsale {
  using SafeMath for uint256;
  uint256 public MAXIMUM_SUPPLY = 100000000 * 10**18;
  uint256 [] public LOCKED = [     20000000 * 10**18,
                                   15000000 * 10**18,
                                    6000000 * 10**18,
                                    6000000 * 10**18 ];
  uint256 public POST_ICO =        21000000 * 10**18;
  uint256 [] public LOCK_END = [
    1570190400,  
    1538654400,  
    1522843200,  
    1515067200   
  ];

  mapping (address => bool) public claimed;
  TokenTimelock [4] public timeLocks;

  event ClaimTokens(address indexed to, uint amount);

  modifier beforeStart() {
    require(block.number < startBlock);
    _;
  }

  function EidooTokenSale(
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rate,
    uint _tokenStartBlock,
    uint _tokenLockEndBlock,
    address _wallet
  )
    Crowdsale(_startBlock, _endBlock, _rate, _wallet)
  {
    token = new EidooToken(_tokenStartBlock, _tokenLockEndBlock);

     
    timeLocks[0] = new TokenTimelock(EidooToken(token), _wallet, LOCK_END[0]);
    timeLocks[1] = new TokenTimelock(EidooToken(token), _wallet, LOCK_END[1]);
    timeLocks[2] = new TokenTimelock(EidooToken(token), _wallet, LOCK_END[2]);
    timeLocks[3] = new TokenTimelock(EidooToken(token), _wallet, LOCK_END[3]);
    token.mint(address(timeLocks[0]), LOCKED[0]);
    token.mint(address(timeLocks[1]), LOCKED[1]);
    token.mint(address(timeLocks[2]), LOCKED[2]);
    token.mint(address(timeLocks[3]), LOCKED[3]);

    token.mint(_wallet, POST_ICO);

     
    tokenCap = MAXIMUM_SUPPLY.sub(EidooToken(token).totalSupply());
  }

  function claimTokens(address [] buyers, uint [] amounts) onlyOwner beforeStart public {
    require(buyers.length == amounts.length);
    uint len = buyers.length;
    for (uint i = 0; i < len; i++) {
      address to = buyers[i];
      uint256 amount = amounts[i];
      if (amount > 0 && !claimed[to]) {
        claimed[to] = true;
        if (to == 0x32Be343B94f860124dC4fEe278FDCBD38C102D88) {
           
          to = 0x2274bebe2b47Ec99D50BB9b12005c921F28B83bB;
        }
        tokenCap = tokenCap.sub(amount);
        uint256 unlockedAmount = amount.div(10).mul(3);
        token.mint(to, unlockedAmount);
        token.mintLocked(to, amount.sub(unlockedAmount));
        ClaimTokens(to, amount);
      }
    }
  }

}