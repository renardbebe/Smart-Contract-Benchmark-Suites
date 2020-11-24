 

pragma solidity ^0.4.4;

 

contract ERC20 {

  uint public totalSupply;
  uint public decimals;

  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}


 
contract Ownable {
   
  address public owner;

   
  address public newOwner;

   
  event OwnershipTransferred(address indexed _from, address indexed _to);

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

   
  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract SafeMathLib {
  function safeMul(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}


 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

   
  function upgradeFrom(address _tokenHolder, uint256 _amount) external;
}


 
contract StandardToken is ERC20, SafeMathLib {

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {

       
      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);
      Transfer(msg.sender, _to, _value);
      return true;

  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {

    uint _allowance = allowed[_from][msg.sender];

     
    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;

  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract CMBUpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function CMBUpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

       
      require(value != 0);

      balances[msg.sender] = safeSub(balances[msg.sender], value);

       
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {


       
      require(canUpgrade());

      require(agent != 0x0);
       
      require(msg.sender == upgradeMaster);
       
      require(getUpgradeState() != UpgradeState.Upgrading);

      upgradeAgent = UpgradeAgent(agent);

       
      require(upgradeAgent.isUpgradeAgent());
       
      require(upgradeAgent.originalSupply() == totalSupply);

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      require(master != 0x0);
      require(msg.sender == upgradeMaster);
      upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        require(transferAgents[_sender]);
    }

    _;
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


  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}


contract Coin is CMBUpgradeableToken, ReleasableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

   
  string public name = "Creatium";

   
  string public symbol = "CMB";

   
  uint public decimals = 18;

 
  uint public totalSupply = 2000000000 * (10 ** decimals);
  uint public onSaleTokens = 30000000 * (10 ** decimals);

  uint256 pricePerToken = 295898260100000;  


  uint minETH = 0 * 10**decimals;
  uint maxETH = 500 * 10**decimals; 


   
  bool public isCrowdsaleOpen=false;
  

  uint tokensForPublicSale = 0;

  address contractAddress;

  

  function Coin() CMBUpgradeableToken(msg.sender) {

    owner = msg.sender;
    contractAddress = address(this);
     
    balances[contractAddress] = totalSupply;
  }

   
  function updateTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }


  function sendTokensToOwner(uint _tokens) onlyOwner returns (bool ok){
      require(balances[contractAddress] >= _tokens);
      balances[contractAddress] = safeSub(balances[contractAddress],_tokens);
      balances[owner] = safeAdd(balances[owner],_tokens);
      return true;
  }


   
  function sendTokensToInvestors(address _investor, uint _tokens) onlyOwner returns (bool ok){
      require(balances[contractAddress] >= _tokens);
      onSaleTokens = safeSub(onSaleTokens, _tokens);
      balances[contractAddress] = safeSub(balances[contractAddress],_tokens);
      balances[_investor] = safeAdd(balances[_investor],_tokens);
      return true;
  }



   
  function dispenseTokensToInvestorAddressesByValue(address[] _addresses, uint[] _value) onlyOwner returns (bool ok){
     require(_addresses.length == _value.length);
     for(uint256 i=0; i<_addresses.length; i++){
        onSaleTokens = safeSub(onSaleTokens, _value[i]);
        balances[_addresses[i]] = safeAdd(balances[_addresses[i]], _value[i]);
        balances[contractAddress] = safeSub(balances[contractAddress], _value[i]);
     }
     return true;
  }


  function startCrowdSale() onlyOwner {
     isCrowdsaleOpen=true;
  }

   function stopCrowdSale() onlyOwner {
     isCrowdsaleOpen=false;
  }


 function setPublicSaleParams(uint _tokensForPublicSale, uint _min, uint _max, bool _crowdsaleStatus ) onlyOwner {
    require(_tokensForPublicSale != 0);
    require(_tokensForPublicSale <= onSaleTokens);
    tokensForPublicSale = _tokensForPublicSale;
    isCrowdsaleOpen=_crowdsaleStatus;
    require(_min >= 0);
    require(_max > _min+1);
    minETH = _min;
    maxETH = _max;
 }


 function setTotalTokensForPublicSale(uint _value) onlyOwner{
      require(_value != 0);
      tokensForPublicSale = _value;
  }

  function setMinAndMaxEthersForPublicSale(uint _min, uint _max) onlyOwner{
      require(_min >= 0);
      require(_max > _min+1);
      minETH = _min;
      maxETH = _max;
  }

  function updateTokenPrice(uint _value) onlyOwner{
      require(_value != 0);
      pricePerToken = _value;
  }


  function updateOnSaleSupply(uint _newSupply) onlyOwner{
      require(_newSupply != 0);
      onSaleTokens = _newSupply;
  }


  function buyTokens() public payable returns(uint tokenAmount) {

    uint _tokenAmount;
    uint multiplier = (10 ** decimals);
    uint weiAmount = msg.value;

    require(isCrowdsaleOpen);
     

    require(weiAmount >= minETH);
    require(weiAmount <= maxETH);

    _tokenAmount =  safeMul(weiAmount,multiplier) / pricePerToken;

    require(_tokenAmount > 0);

     
    tokensForPublicSale = safeSub(tokensForPublicSale, _tokenAmount);
    onSaleTokens = safeSub(onSaleTokens, _tokenAmount);
    balances[contractAddress] = safeSub(balances[contractAddress],_tokenAmount);
     
    balances[msg.sender] = safeAdd(balances[msg.sender], _tokenAmount);

     
    require(owner.send(weiAmount));

    return _tokenAmount;

  }

   

  function() payable {
      buyTokens();
  }

  function destroyToken() public onlyOwner {
      selfdestruct(msg.sender);
  }

}