 

pragma solidity ^0.4.18;

 
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

 
 contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
   function Ownable() public { owner = msg.sender; }

   
   modifier onlyOwner() { require(msg.sender == owner); _; }


   
   function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
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
    require(_value <= balances[msg.sender]);

     
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
     
    assert(allowed[msg.sender][_spender] == 0 || _value == 0);
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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

 

 contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
   function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
   function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 contract TracToken is MintableToken {

  string public constant name = 'Trace Token';
  string public constant symbol = 'TRAC';
  uint8 public constant decimals = 18;  
  uint256 public startTime = 1516028400;  
  uint256 public constant bountyReward = 1e25;
  uint256 public constant preicoAndAdvisors = 4e25;
  uint256 public constant liquidityPool = 25e24;
  uint256 public constant futureDevelopment = 1e26; 
  uint256 public constant teamAndFounders = 75e24;
  uint256 public constant CORRECTION = 9605598917469000000000;   

   
  uint256[8] public founderAmounts = [uint256( teamAndFounders.div(8).sub(CORRECTION) ),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8),teamAndFounders.div(8)];
  uint256[2] public preicoAndAdvisorsAmounts = [ uint256(preicoAndAdvisors.mul(2).div(5)),preicoAndAdvisors.mul(2).div(5)];

   
  address public wallet;

   
  address public teamAndFoundersWallet;

   
  address public advisorsAndPreICO;
  uint256 public TOTAL_NUM_TOKENS = 5e26;


  function TracToken(address _wallet,address _teamAndFoundersWallet,address _advisorsAndPreICO) public {
    require(_wallet!=0x0);
    require(_teamAndFoundersWallet!=0x0);
    require(_advisorsAndPreICO!=0x0);
    wallet = _wallet;
    teamAndFoundersWallet = _teamAndFoundersWallet;
    advisorsAndPreICO = _advisorsAndPreICO;
  }


  event Transfer(address indexed from, address indexed to, uint256 value);
  event TransferAllowed(bool transferIsAllowed);

  modifier canTransfer() {
    require(mintingFinished);
    _;        
  }

  function transferFrom(address from, address to, uint256 value) canTransfer public returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function transfer(address to, uint256 value) canTransfer public returns (bool) {
    return super.transfer(to, value);
  }

  function mint(address contributor, uint256 amount) onlyOwner public returns (bool) {
    return super.mint(contributor, amount);
  }

  function mintMany(address[] contributors, uint256[] amounts) onlyOwner public returns (bool) {
     address contributor;
     uint256 amount;
     require(contributors.length == amounts.length);

     for (uint i = 0; i < contributors.length; i++) {
      contributor = contributors[i];
      amount = amounts[i];
      require(mint(contributor, amount));
    }
    return true;
  }

  function endMinting() onlyOwner public returns (bool) {
    require(!mintingFinished);
    TransferAllowed(true);
    return super.finishMinting();
  }

  function withdrawTokenToFounders() public {
  
    if (now > startTime + 720 days && founderAmounts[7]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[7]);
      founderAmounts[7] = 0;
    }

    if (now > startTime + 630 days && founderAmounts[6]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[6]);
      founderAmounts[6] = 0;
    }
    if (now > startTime + 540 days && founderAmounts[5]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[5]);
      founderAmounts[5] = 0;
    }
    if (now > startTime + 450 days && founderAmounts[4]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[4]);
      founderAmounts[4] = 0;
    }
    if (now > startTime + 360 days&& founderAmounts[3]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[3]);
      founderAmounts[3] = 0;
    }
    if (now > startTime + 270 days && founderAmounts[2]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[2]);
      founderAmounts[2] = 0;
    }
    if (now > startTime + 180 days && founderAmounts[1]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[1]);
      founderAmounts[1] = 0;
    }
    if (now > startTime + 90 days && founderAmounts[0]>0){
      this.transfer(teamAndFoundersWallet, founderAmounts[0]);
      founderAmounts[0] = 0;
    }
  }

  function withdrawTokensToAdvisors() public {
    if (now > startTime + 180 days && preicoAndAdvisorsAmounts[1]>0){
      this.transfer(advisorsAndPreICO, preicoAndAdvisorsAmounts[1]);
      preicoAndAdvisorsAmounts[1] = 0;
    }

    if (now > startTime + 90 days && preicoAndAdvisorsAmounts[0]>0){
      this.transfer(advisorsAndPreICO, preicoAndAdvisorsAmounts[0]);
      preicoAndAdvisorsAmounts[0] = 0;
    }
  }


  function allocateRestOfTokens() onlyOwner public{
    require(totalSupply > TOTAL_NUM_TOKENS.div(2));
    require(totalSupply < TOTAL_NUM_TOKENS);
    require(!mintingFinished);
    mint(wallet, bountyReward);
    mint(advisorsAndPreICO,  preicoAndAdvisors.div(5));
    mint(wallet, liquidityPool);
    mint(wallet, futureDevelopment);
    mint(this, teamAndFounders.sub(CORRECTION));
    mint(this, preicoAndAdvisors.mul(4).div(5));
  }

}