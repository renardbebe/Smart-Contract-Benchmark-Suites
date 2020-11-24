 

pragma solidity ^0.4.14;




contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
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
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

   
    uint256 public startBlock;
    uint256 public endBlock;
   
    address public wallet;

   
    uint256 public tokensPerEther;

   
    uint256 public weiRaised;

    uint256 public cap;
    uint256 public issuedTokens;
    string public name = "Enter-Coin";
    string public symbol = "ENTRC";
    uint public decimals = 8;
    uint public INITIAL_SUPPLY = 100000000 * (10**decimals);
    address founder; 
    uint internal factor;
    bool internal isCrowdSaleRunning;
    uint contractDeployedTime;
    uint mf = 10**decimals;  

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Token() { 
  
    

    wallet = address(0x6D6D8fDFeFDA898341a60340a5699769Af2BA350); 
    founder = address(0x0CC74179395d9434C9A31586763861327C499E76);  

    tokensPerEther = 306;  
    endBlock = block.number + 1000000;

    totalSupply = INITIAL_SUPPLY;
                           
    balances[msg.sender] = (25000000 * mf) + (65000000 * mf);
    balances[founder] = 10000000 * mf;

    startBlock = block.number;    
    cap = 65000000 * mf;
    issuedTokens = 0;
    factor = 10**10;
    isCrowdSaleRunning = true;
    contractDeployedTime = now;

    }

     
     

  function () payable {
    buyTokens(msg.sender);
  }
  
  function getTimePassed() public constant returns (uint256) {
      return (now - contractDeployedTime).div(1 days);
  }
   
  function applyBonus(uint256 tokens) internal constant returns (uint256) {

    if ( (now < (contractDeployedTime + 14 days)) && (issuedTokens < (3500000*mf)) ) {

      return tokens.mul(20).div(10);  
      
    } else if ((now < (contractDeployedTime + 20 days)) && (issuedTokens < (13500000*mf)) ) {
    
      return tokens.mul(15).div(10);  
    

    } else if ((now < (contractDeployedTime + 26 days)) && (issuedTokens < (23500000*mf)) ) {

      return tokens.mul(13).div(10);  

    } else if ((now < (contractDeployedTime + 32 days)) && (issuedTokens < (33500000*mf)) ) {

      return tokens.mul(12).div(10);  

    } else if ((now < (contractDeployedTime + 38 days)) && (issuedTokens < (43500000*mf)) ) {
      return tokens.mul(11).div(10);  

    } 

    return tokens;  

  }

   
  function stopCrowdSale() onlyOwner {
    isCrowdSaleRunning = false;
    endBlock = block.number;
  }

  function resetContractDeploymentDate() onlyOwner {
      contractDeployedTime = now;
  }

  function startCrowdsale(uint interval) onlyOwner {
    if ( endBlock < block.number ) {
      endBlock = block.number;   
    }

    endBlock = endBlock.add(interval);
    isCrowdSaleRunning = true;
  }

  function setWallet(address newWallet) onlyOwner {
    require(newWallet != address(0));
    wallet = newWallet;
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(tokensPerEther).div(factor);

    tokens = applyBonus(tokens);
    
     
    require(issuedTokens.add(tokens) <= cap);
     
    weiRaised = weiRaised.add(weiAmount);
    issuedTokens = issuedTokens.add(tokens);

    forwardFunds();
     
    issueToken(beneficiary,tokens);
    TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

  }

  function setFounder(address newFounder) onlyOwner {
    require(newFounder != address(0));
    founder = newFounder; 
  }

   
  function issueToken(address beneficiary, uint256 tokens) internal {
    balances[owner] = balances[owner].sub(tokens);
    balances[beneficiary] = balances[beneficiary].add(tokens);
  }

   
   
  function forwardFunds() internal {
     
    wallet.transfer(msg.value);
  
  }

   
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock && current <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && isCrowdSaleRunning;
  }

   
  function hasEnded() public constant returns (bool) {
      return (block.number > endBlock) || !isCrowdSaleRunning;
  }

}