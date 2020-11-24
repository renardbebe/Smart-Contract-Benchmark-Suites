 

pragma solidity ^0.4.19;

 

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }
  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
   require(msg.data.length >= size + 4);
   _;
  }

   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0) &&
        _value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint)) internal allowed;

   
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_to != address(0) &&
        _value <= balances[_from] &&
        _value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract BRXToken is StandardToken, Ownable {
  using SafeMath for uint;

   
  string public constant name = "BRX Coin";
  string public constant symbol = "BRX";
  uint8 public constant decimals = 18;

   
  uint private constant atto = 1000000000000000000;
  uint private constant INITIAL_SUPPLY = 15000000 * atto;  
  uint public totalSupply = INITIAL_SUPPLY;

   
   
  address public ico_address = 0x1F01f01f01f01F01F01f01F01F01f01F01f01F01;
  address public teamWallet = 0x58096c1dCd5f338530770B1f6Fe0AcdfB90Cc87B;
  address public addrBRXPay = 0x2F02F02F02F02f02f02f02f02F02F02f02f02f02;

  uint private current_supply = 0;  
  uint private ico_starting_supply = 0;  
  uint private current_price_atto_tokens_per_wei = 0;  

   
  bool private preSoldSharesDistributed = false;  
  bool private isICOOpened = false;
  bool private isICOClosed = false;
   
   
   
   

   
  uint public founderMembers = 0;
  mapping(uint => address) private founderOwner;
  mapping(address => uint) founderMembersInvest;
  
   
  uint[] private premiumPacks;
  mapping(address => bool) private premiumICOMember;
  mapping(address => uint) private premiumPacksPaid;
  mapping(address => bool) public frozenAccounts;

   
  event ICOOpened();
  event ICOClosed();

  event PriceChanged(uint old_price, uint new_price);
  event SupplyChanged(uint supply, uint old_supply);

  event FrozenFund(address _from, bool _freeze);

  event BRXAcquired(address account, uint amount_in_wei, uint amount_in_brx);
  event BRXNewFounder(address account, uint amount_in_brx);

   
   

  function BRXToken() public {
     
     
    distributePreSoldShares();

     
    current_price_atto_tokens_per_wei = calculateCurrentPrice(1);

     
    premiumPacks.length = 0;
  }

   
  function () public payable {
    buy();
  }

   
   
   
  function transferAnyERC20Token(
    address tokenAddress, uint tokens
  ) public onlyOwner
    returns (bool success) {
    return StandardToken(tokenAddress).transfer(owner, tokens);
  }

   

   
   
   
   
  function buy() public payable {
    require(msg.value != 0 && isICOOpened == true && isICOClosed == false);

     
    uint tokens = getAttoTokensAmountPerWeiInternal(msg.value);

     
    uint allowedInOneTransaction = current_supply / 100;
    require(tokens < allowedInOneTransaction &&
        tokens <= balances[ico_address]);

     
    balances[ico_address] = balances[ico_address].sub(tokens);  
    balances[msg.sender] = balances[msg.sender].add(tokens);
    premiumICOMember[msg.sender] = true;
    
     
    if (balances[msg.sender] >= 2000000000000000000000) {
        if (founderMembersInvest[msg.sender] == 0) {
            founderOwner[founderMembers] = msg.sender;
            founderMembers++; BRXNewFounder(msg.sender, balances[msg.sender]);
        }
        founderMembersInvest[msg.sender] = balances[msg.sender];
    }

     
    uint old_price = current_price_atto_tokens_per_wei;
    current_price_atto_tokens_per_wei = calculateCurrentPrice(getAttoTokensBoughtInICO());
    if (current_price_atto_tokens_per_wei == 0) current_price_atto_tokens_per_wei = 1;  
    if (current_price_atto_tokens_per_wei > old_price) current_price_atto_tokens_per_wei = old_price;  

     
    if (old_price != current_price_atto_tokens_per_wei) PriceChanged(old_price, current_price_atto_tokens_per_wei);

     
    BRXAcquired(msg.sender, msg.value, tokens);
  }

   
  function calculateCurrentPrice(
    uint attoTokensBought
  ) private pure
    returns (uint result) {
     
     
    return (395500000 / ((attoTokensBought / atto) + 150000)).sub(136);
  }

   
   

  function openICO() public onlyOwner {
    require(isICOOpened == false && isICOClosed == false);
    isICOOpened = true;

    ICOOpened();
  }
  function closeICO() public onlyOwner {
    require(isICOClosed == false && isICOOpened == true);

    isICOOpened = false;
    isICOClosed = true;

     
    premiumPacks.length = 1;
    premiumPacks[0] = balances[ico_address];
    balances[ico_address] = 0;

    ICOClosed();
  }
  function pullEtherFromContract() public onlyOwner {
    require(isICOClosed == true);  
    if (!teamWallet.send(this.balance)) {
      revert();
    }
  }
  function freezeAccount(
    address _from, bool _freeze
  ) public onlyOwner
    returns (bool) {
    frozenAccounts[_from] = _freeze;
    FrozenFund(_from, _freeze);  
    return true;
  }
  function setNewBRXPay(
    address newBRXPay
  ) public onlyOwner {
    require(newBRXPay != address(0));
    addrBRXPay = newBRXPay;
  }
  function transferFromBRXPay(
    address _from, address _to, uint _value
  ) public allowedPayments
    returns (bool) {
    require(msg.sender == addrBRXPay && balances[_to].add(_value) > balances[_to] &&
    _value <= balances[_from] && !frozenAccounts[_from] &&
    !frozenAccounts[_to] && _to != address(0));
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function setCurrentPricePerWei(
    uint _new_price  
  ) public onlyOwner
  returns (bool) {
    require(isICOClosed == true && _new_price > 0);  
    uint old_price = current_price_atto_tokens_per_wei;
    current_price_atto_tokens_per_wei = _new_price;
    PriceChanged(old_price, current_price_atto_tokens_per_wei);
  }

   
   
   

  function distributePreSoldShares() private onlyOwner {
     
    require(preSoldSharesDistributed == false);
    preSoldSharesDistributed = true;

     
    balances[0xAEC5cbcCF89fc25e955A53A5a015f7702a14b629] = 7208811 * atto;
    balances[0xAECDCB2a8e2cFB91869A9af30050BEa038034949] = 4025712 * atto;
    balances[0xAECF0B1b6897195295FeeD1146F3732918a5b3E4] = 300275 * atto;
    balances[0xAEC80F0aC04f389E84F3f4b39827087e393EB229] = 150000 * atto;
    balances[0xAECc9545385d858D3142023d3c298a1662Aa45da] = 150000 * atto;
    balances[0xAECE71616d07F609bd2CbD4122FbC9C4a2D11A9D] = 90000 * atto;
    balances[0xAECee3E9686825e0c8ea65f1bC8b1aB613545B8e] = 75000 * atto;
    balances[0xAECC8E8908cE17Dd6dCFFFDCCD561696f396148F] = 202 * atto;
    current_supply = (7208811 + 4025712 + 300275 + 150000 + 150000 + 90000 + 75000 + 202) * atto;

     
    balances[ico_address] = INITIAL_SUPPLY.sub(current_supply);

     
    ico_starting_supply = balances[ico_address];
    current_supply = INITIAL_SUPPLY;
    SupplyChanged(0, current_supply);
  }

   
   

  function getIcoStatus() public view
    returns (string result) {
    return (isICOClosed) ? 'closed' : (isICOOpened) ? 'opened' : 'not opened' ;
  }
  function getCurrentPricePerWei() public view
    returns (uint result) {
    return current_price_atto_tokens_per_wei;
  }
  function getAttoTokensAmountPerWeiInternal(
    uint value
  ) public payable
    returns (uint result) {
    return value * current_price_atto_tokens_per_wei;
  }
  function getAttoTokensAmountPerWei(
    uint value
  ) public view
  returns (uint result) {
    return value * current_price_atto_tokens_per_wei;
  }
  function getAttoTokensLeftForICO() public view
    returns (uint result) {
    return balances[ico_address];
  }
  function getAttoTokensBoughtInICO() public view
    returns (uint result) {
    return ico_starting_supply - getAttoTokensLeftForICO();
  }
  function getPremiumPack(uint index) public view
    returns (uint premium) {
    return premiumPacks[index];
  }
  function getPremiumsAvailable() public view
    returns (uint length) {
    return premiumPacks.length;
  }
  function getBalancePremiumsPaid(
    address account
  ) public view
    returns (uint result) {
    return premiumPacksPaid[account];
  }
  function getAttoTokensToBeFounder() public view
  returns (uint result) {
    return 2000000000000000000000 / getCurrentPricePerWei();
  }
  function getFounderMembersInvest(
    address account
  ) public view
    returns (uint result) {
    return founderMembersInvest[account];
  }
  function getFounderMember(
    uint index
  ) public onlyOwner view
    returns (address account) {
    require(founderMembers >= index && founderOwner[index] != address(0));
    return founderOwner[index];
  }

   
   

  function sendPremiumPack(
    uint amount
  ) public onlyOwner allowedPayments {
    premiumPacks.length += 1;
    premiumPacks[premiumPacks.length-1] = amount;
    balances[msg.sender] = balances[msg.sender].sub(amount);  
  }
  function getPremiums() public allowedPayments
    returns (uint amount) {
    require(premiumICOMember[msg.sender]);
    if (premiumPacks.length > premiumPacksPaid[msg.sender]) {
      uint startPackIndex = premiumPacksPaid[msg.sender];
      uint finishPackIndex = premiumPacks.length - 1;
      uint owingTotal = 0;
      for(uint i = startPackIndex; i <= finishPackIndex; i++) {
        if (current_supply != 0) {  
          uint owing = balances[msg.sender] * premiumPacks[i] / current_supply;
          balances[msg.sender] = balances[msg.sender].add(owing);
          owingTotal = owingTotal + owing;
        }
      }
      premiumPacksPaid[msg.sender] = premiumPacks.length;
      return owingTotal;
    } else {
      revert();
    }
  }

   
   

  modifier allowedPayments() {
     
    require(isICOOpened == false && isICOClosed == true && !frozenAccounts[msg.sender]);
    _;
  }
  
  function transferFrom(
    address _from, address _to, uint _value
  ) public allowedPayments
    returns (bool) {
    super.transferFrom(_from, _to, _value);
  }
  
  function transfer(
    address _to, uint _value
  ) public onlyPayloadSize(2 * 32) allowedPayments
    returns (bool) {
    super.transfer(_to, _value);
  }

}