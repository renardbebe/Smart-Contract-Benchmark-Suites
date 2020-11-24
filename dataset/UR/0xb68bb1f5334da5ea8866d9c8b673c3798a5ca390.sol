 

pragma solidity ^0.4.2;

 
 
library SafeMathLib {

  function times(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a);
    return c;
  }
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }

}

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public  returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
}



 
contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

   
   
   
}



 
contract StandardToken is ERC20, SafeMath {

   
   event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public pure returns (bool weAre) {
    return true;
  }

   
  modifier onlyPayloadSize(uint size) {
      
     _;
  }

  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
    require(_value >= 0);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

     
    require(_allowance >= _value);
    require(_value >= 0);

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value)public returns (bool success) {

     
     
     
     
     
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }  
    return size > 0;
  }
}



 
contract Ownable {
  address public owner;
  mapping (address => bool) private admins;
  mapping (address => bool) private developers;
  mapping (address => bool) private founds;

  function Ownable()  internal{
    owner = msg.sender;
  }

  modifier onlyAdmins(){
    require(admins[msg.sender]);
    _;
  }

  modifier onlyOwner()  {
    require (msg.sender == owner);
    _;
  }

 function getOwner() view public returns (address){
     return owner;
  }

 function isDeveloper () view internal returns (bool) {
     return developers[msg.sender];
  }

 function isFounder () view internal returns (bool){
     return founds[msg.sender];
  }

  function addDeveloper (address _dev) onlyOwner() public {
    developers[_dev] = true;
  }

  function removeDeveloper (address _dev) onlyOwner() public {
    delete developers[_dev];
  }

    function addFound (address _found) onlyOwner() public {
    founds[_found] = true;
  }

  function removeFound (address _found) onlyOwner() public {
    delete founds[_found];
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 
contract DistributeToken is StandardToken, Ownable{

  event AirDrop(address from, address to, uint amount);
  event CrowdDistribute(address from, address to, uint amount);

  using SafeMathLib for uint;

   
  address public distAgent;

  uint public maxAirDrop = 1000*10**18; 

  uint public havedAirDrop = 0;
  uint public totalAirDrop = 0;  

  bool public finishCrowdCoin = false;
  uint public havedCrowdCoin = 0;
  uint public totalCrowdCoin = 0;  

  uint public havedDistDevCoin = 0;
  uint public totalDevCoin = 0;   

  uint public havedDistFoundCoin = 0;
  uint public totalFoundCoin = 0;   

   
  uint private crowState = 0; 
   
  function setDistributeAgent(address addr) onlyOwner  public {
     
     require(addr != address(0));

     
    distAgent = addr;
  }


   
  modifier onlyDistributeAgent() {
    require(msg.sender == distAgent) ;
    _;
  }

   
   
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  
 function distributeToFound(address receiver, uint amount) onlyOwner() public  returns (uint actual){ 
  
    require((amount+havedDistFoundCoin) < totalFoundCoin);
  
    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedDistFoundCoin = havedDistFoundCoin.plus(amount);

    addFound(receiver);

     
     
    emit Transfer(0, receiver, amount);
   
    return amount;
 }

  
 function  distributeToDev(address receiver, uint amount) onlyOwner()  public  returns (uint actual){

    require((amount+havedDistDevCoin) < totalDevCoin);

    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedDistDevCoin = havedDistDevCoin.plus(amount);

    addDeveloper(receiver);
     
     
    emit Transfer(0, receiver, amount);

    return amount;
 }

  
 function airDrop(address transmitter, address receiver, uint amount) public  returns (uint actual){

    require(receiver != address(0));
    require(amount <= maxAirDrop);
    require((amount+havedAirDrop) < totalAirDrop);
    require(transmitter == distAgent);

    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedAirDrop = havedAirDrop.plus(amount);

     
     
    emit AirDrop(0, receiver, amount);

    return amount;
  }

  
 function crowdDistribution() payable public  returns (uint actual) {
      
    require(msg.sender != address(0));
    require(!isContract(msg.sender));
    require(msg.value != 0);
    require(totalCrowdCoin > havedCrowdCoin);
    require(finishCrowdCoin == false);
    
    uint actualAmount = calculateCrowdAmount(msg.value);

    require(actualAmount != 0);

    havedCrowdCoin = havedCrowdCoin.plus(actualAmount);
    balances[owner] = balances[owner].sub(actualAmount);
    balances[msg.sender] = balances[msg.sender].plus(actualAmount);
    
    switchCrowdState();
    
     
     
    emit CrowdDistribute(0, msg.sender, actualAmount);

    return actualAmount;
  }

 function  switchCrowdState () internal{

    if (havedCrowdCoin < totalCrowdCoin.mul(10).div(100) ){
       crowState = 0;

    }else  if (havedCrowdCoin < totalCrowdCoin.mul(20).div(100) ){
       crowState = 1;
    
    } else if (havedCrowdCoin < totalCrowdCoin.mul(30).div(100) ){
       crowState = 2;

    } else if (havedCrowdCoin < totalCrowdCoin.mul(40).div(100) ){
       crowState = 3;

    } else if (havedCrowdCoin < totalCrowdCoin.mul(50).div(100) ){
       crowState = 4;
    }
      
    if (havedCrowdCoin >= totalCrowdCoin) {
       finishCrowdCoin = true;
  }
 }

function calculateCrowdAmount (uint _price) internal view returns (uint _crow) {
        
    if (crowState == 0) {
      return _price.mul(50000);
    }
    
     else if (crowState == 1) {
      return _price.mul(30000);
    
    } else if (crowState == 2) {
      return  _price.mul(20000);

    } else if (crowState == 3) {
     return  _price.mul(15000);

    } else if (crowState == 4) {
     return  _price.mul(10000);
    }

    return 0;
  }

}

 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

  uint private maxTransferForDev  = 40000000*10**18;
  uint private maxTransferFoFounds= 20000000*10**18;
  uint private maxTransfer = 0; 

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender, uint _value) {

     
    if(_sender != owner){
      
      if(isDeveloper()){
        require(_value < maxTransferForDev);

      }else if(isFounder()){
        require(_value < maxTransferFoFounds);

      }else if(maxTransfer != 0){
        require(_value < maxTransfer);
      }

      if(!released) {
          require(transferAgents[_sender]);
      }
     }
    _;
  }


 function setMaxTranferLimit(uint dev, uint found, uint other) onlyOwner  public {

      require(dev < totalSupply);
      require(found < totalSupply);
      require(other < totalSupply);

      maxTransferForDev = dev;
      maxTransferFoFounds = found;
      maxTransfer = other;
  }


   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender,_value) returns (bool success)  {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from,_value) returns (bool success)  {
     
    return super.transferFrom(_from, _to, _value);
  }

}

contract RecycleToken is StandardToken, Ownable {

  using SafeMathLib for uint;

   
  function recycle(address from, uint amount) onlyAdmins public {
  
    require(from != address(0));
    require(balances[from] >=  amount);

    balances[owner] = balances[owner].add(amount);
    balances[from]  = balances[from].sub(amount);

     
     
    emit Transfer(from, owner, amount);
  }

}


 
contract MintableToken is StandardToken, Ownable {

  using SafeMathLib for uint;

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {

     
    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    
     
     
    emit Transfer(0, receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

  function enableMint() onlyOwner public {
    mintingFinished = false;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}



 
contract TTGCoin is ReleasableToken, MintableToken , DistributeToken, RecycleToken{

   
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

   
  function TTGCoin() public {
     
     
    owner = msg.sender;

    addAdmin(owner);

    name  = "TotalGame Coin";
    symbol = "TGC";
    totalSupply = 2000000000*10**18;
    decimals = 18;

     
    balances[msg.sender] = totalSupply;

     
    mintingFinished = true;

     
    totalAirDrop = totalSupply.mul(10).div(100);
    totalCrowdCoin = totalSupply.mul(50).div(100);
    totalDevCoin = totalSupply.mul(20).div(100);
    totalFoundCoin = totalSupply.mul(20).div(100);

    emit Minted(owner, totalSupply);
  }


   
  function releaseTokenTransfer() public onlyReleaseAgent {
    super.releaseTokenTransfer();
  }

   
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    emit UpdatedTokenInformation(name, symbol);
  }

  function getTotalSupply() public view returns (uint) {
    return totalSupply;
  }

  function tokenName() public view returns (string _name) {
    return name;
  }
}