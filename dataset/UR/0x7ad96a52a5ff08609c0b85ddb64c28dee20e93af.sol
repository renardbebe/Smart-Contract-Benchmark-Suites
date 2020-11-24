 

pragma solidity ^0.4.18;

 
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

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract OpportyToken is StandardToken {

  string public constant name = "OpportyToken";
  string public constant symbol = "OPP";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

   
  function OpportyToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract HoldSaleContract is Ownable {
  using SafeMath for uint256;
   
  OpportyToken public OppToken;

  struct Holder {
    bool isActive;
    uint tokens;
    uint holdPeriodTimestamp;
    bool withdrawed;
  }

  mapping(address => Holder) public holderList;
  mapping(uint => address) private holderIndexes;

  mapping (uint => address) private assetOwners;
  mapping (address => uint) private assetOwnersIndex;
  uint private assetOwnersIndexes;

  uint private holderIndex;
  uint private holderWithdrawIndex;

  uint private tokenAddHold;
  uint private tokenWithdrawHold;

  event TokensTransfered(address contributor , uint amount);
  event Hold(address sender, address contributor, uint amount, uint holdPeriod);

  modifier onlyAssetsOwners() {
    require(assetOwnersIndex[msg.sender] > 0);
    _;
  }

   
  function HoldSaleContract(address _OppToken) public {
    OppToken = OpportyToken(_OppToken);
    addAssetsOwner(msg.sender);
  }

  function addHolder(address holder, uint tokens, uint timest) onlyAssetsOwners external {
    if (holderList[holder].isActive == false) {
      holderList[holder].isActive = true;
      holderList[holder].tokens = tokens;
      holderList[holder].holdPeriodTimestamp = timest;
      holderIndexes[holderIndex] = holder;
      holderIndex++;
    } else {
      holderList[holder].tokens += tokens;
      holderList[holder].holdPeriodTimestamp = timest;
    }
    tokenAddHold += tokens;
    Hold(msg.sender, holder, tokens, timest);
  }

  function getBalance() public constant returns (uint) {
    return OppToken.balanceOf(this);
  }

  function unlockTokens() external {
    address contributor = msg.sender;

    if (holderList[contributor].isActive && !holderList[contributor].withdrawed) {
      if (now >= holderList[contributor].holdPeriodTimestamp) {
        if ( OppToken.transfer( msg.sender, holderList[contributor].tokens ) ) {
          TokensTransfered(contributor,  holderList[contributor].tokens);
          tokenWithdrawHold += holderList[contributor].tokens;
          holderList[contributor].withdrawed = true;
          holderWithdrawIndex++;
        }
      } else {
        revert();
      }
    } else {
      revert();
    }
  }

  function addAssetsOwner(address _owner) public onlyOwner {
    assetOwnersIndexes++;
    assetOwners[assetOwnersIndexes] = _owner;
    assetOwnersIndex[_owner] = assetOwnersIndexes;
  }
  function removeAssetsOwner(address _owner) public onlyOwner {
    uint index = assetOwnersIndex[_owner];
    delete assetOwnersIndex[_owner];
    delete assetOwners[index];
    assetOwnersIndexes--;
  }
  function getAssetsOwners(uint _index) onlyOwner public constant returns (address) {
    return assetOwners[_index];
  }

  function getOverTokens() public onlyOwner {
    require(getBalance() > (tokenAddHold - tokenWithdrawHold));
    uint balance = getBalance() - (tokenAddHold - tokenWithdrawHold);
    if(balance > 0) {
      if(OppToken.transfer(msg.sender, balance)) {
        TokensTransfered(msg.sender,  balance);
      }
    }
  }

  function getTokenAddHold() onlyOwner public constant returns (uint) {
    return tokenAddHold;
  }
  function getTokenWithdrawHold() onlyOwner public constant returns (uint) {
    return tokenWithdrawHold;
  }
  function getHolderIndex() onlyOwner public constant returns (uint) {
    return holderIndex;
  }
  function getHolderWithdrawIndex() onlyOwner public constant returns (uint) {
    return holderWithdrawIndex;
  }
}

contract TokenSale is Pausable {
  using SafeMath for uint256;

  OpportyToken public token;

  HoldSaleContract public holdContract;

  enum SaleState  { NEW, SALE, ENDED }
  SaleState public state;

  uint public endDate;
  uint public unholdDate;
  uint public minimalContribution;

   
  address private wallet;

   
  uint private ethRaised;

  uint private price;
  uint8 private bonus;

  uint private tokenRaised;
  bool public tokensTransferredToHold;

   
  event SaleStarted(uint blockNumber);
  event SaleEnded(uint blockNumber);
  event FundTransfered(address contrib, uint amount);
  event WithdrawedEthToWallet(uint amount);
  event ManualChangeEndDate(uint beforeDate, uint afterDate);
  event ManualChangeUnholdDate(uint beforeDate, uint afterDate);
  event TokensTransferedToHold(address hold, uint amount);
  event AddedToHolder(address sender, uint tokenAmount, uint holdTimestamp);
  event ChangeMinAmount(uint oldMinAmount, uint minAmount);

  mapping (uint => address) private assetOwners;
  mapping (address => uint) private assetOwnersIndex;
  uint private assetOwnersIndexes;

  modifier onlyAssetsOwners() {
    require(assetOwnersIndex[msg.sender] > 0);
    _;
  }

   
  function TokenSale(address tokenAddress, address walletAddress, uint end, uint endHoldDate, address holdCont) public {
    token = OpportyToken(tokenAddress);
    state = SaleState.NEW;

    endDate     = end;
    unholdDate  = endHoldDate;
    price       = 0.0002 * 1 ether;
    wallet      = walletAddress;
    minimalContribution = 0.1 * 1 ether;
    bonus = 0;

    holdContract = HoldSaleContract(holdCont);
    addAssetsOwner(msg.sender);
  }

  function() whenNotPaused public payable {
    require(state == SaleState.SALE);
    require(msg.value >= minimalContribution);

    if (now > endDate) {
      state = SaleState.ENDED;
      SaleEnded(block.number);
      msg.sender.transfer(msg.value);
      return ;
    }

    ethRaised += msg.value;

    uint tokenAmount  = msg.value.div(price);
    tokenAmount += tokenAmount.mul(bonus).div(100);
    tokenAmount *= 1 ether;

    tokenRaised += tokenAmount;

    holdContract.addHolder(msg.sender, tokenAmount, unholdDate);
    AddedToHolder(msg.sender, tokenAmount, unholdDate);
    FundTransfered(msg.sender, msg.value);

     
    forwardFunds();
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function getBalanceContract() view internal returns (uint) {
    return token.balanceOf(this);
  }

  function startSale() public onlyOwner {
    require(state == SaleState.NEW);
    state = SaleState.SALE;
    SaleStarted(block.number);
  }
  function endSale() public onlyOwner {
    require(state == SaleState.SALE);
    state = SaleState.ENDED;
    SaleEnded(block.number);
  }

  function sendTokensToHold() public onlyOwner {
    require(state == SaleState.ENDED);

    require(getBalanceContract() >= tokenRaised);

    if (token.transfer(holdContract, tokenRaised )) {
      tokensTransferredToHold = true;
      TokensTransferedToHold(holdContract, tokenRaised );
    }
  }
  function getTokensBack() public onlyOwner {
    require(state == SaleState.ENDED);
    require(tokensTransferredToHold == true);
    uint balance;
    balance = getBalanceContract() ;
    token.transfer(msg.sender, balance);
  }
  function withdrawEth() public {
    require(this.balance != 0);
    require(state == SaleState.ENDED);
    require(msg.sender == wallet);
    require(tokensTransferredToHold == true);
    uint bal = this.balance;
    wallet.transfer(bal);
    WithdrawedEthToWallet(bal);
  }

  function setUnholdDate(uint date) public onlyOwner {
    require(state == SaleState.NEW || state == SaleState.SALE);
    uint oldEndDate = unholdDate;
    unholdDate = date;
    ManualChangeUnholdDate(oldEndDate, date);
  }
  function setEndDate(uint date) public onlyOwner {
    require(state == SaleState.NEW || state == SaleState.SALE);
    require(date > now);
    uint oldEndDate = endDate;
    endDate = date;
    ManualChangeEndDate(oldEndDate, date);
  }
  function setMinimalContribution(uint minimumAmount) public onlyOwner {
    uint oldMinAmount = minimalContribution;
    minimalContribution = minimumAmount;
    ChangeMinAmount(oldMinAmount, minimalContribution);
  }
  function setBonus(uint8 newBonus) public onlyOwner {
    require(newBonus >= 0);
    bonus = newBonus;
  }

  function addAssetsOwner(address _owner) public onlyOwner {
    assetOwnersIndexes++;
    assetOwners[assetOwnersIndexes] = _owner;
    assetOwnersIndex[_owner] = assetOwnersIndexes;
  }
  function removeAssetsOwner(address _owner) public onlyOwner {
    uint index = assetOwnersIndex[_owner];
    delete assetOwnersIndex[_owner];
    delete assetOwners[index];
    assetOwnersIndexes--;
  }
  function getAssetsOwners(uint _index) onlyOwner public constant returns (address) {
    return assetOwners[_index];
  }

  function getTokenBalance() onlyAssetsOwners public constant returns (uint) {
    return token.balanceOf(this);
  }
  function getEthRaised() onlyAssetsOwners public constant returns (uint) {
    return ethRaised;
  }
  function getBonus() onlyAssetsOwners public constant returns (uint) {
    return bonus;
  }
  function getTokenRaised() onlyAssetsOwners public constant returns (uint) {
    return tokenRaised;
  }
}