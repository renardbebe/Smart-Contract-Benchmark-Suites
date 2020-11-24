 

pragma solidity ^0.4.15;

 


contract Ownable {

  address public owner;    

  event OwnershipTransferred ( address indexed prev_owner, address indexed new_owner );

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership (address new_owner) onlyOwner public {
    require(new_owner != address(0));
    OwnershipTransferred(owner, new_owner);
    owner = new_owner;
  }


}  


 
 
 

contract PulsarToken is Ownable {

   

   
  uint public constant TOKEN_SCALE = 1 ether / 1 wei;  

   
  uint public constant TOTAL_SUPPLY = 34540000 * TOKEN_SCALE;

   
  uint public constant ICO_START_TIME = 1510560780;

   
  uint public constant MIN_ACCEPTED_VALUE = 100000000000000000 wei;  

   
  uint public constant MIN_BUYBACK_VALUE = 1 * TOKEN_SCALE;

   
  string public constant NAME = "Pulsar";        
  string public constant SYMBOL = "PVC";         


   
  enum ContractState { Deployed, ICOStarted, ICOStopped, BuybackEnabled, BuybackPaused, Destroyed }

   
  ContractState private contractState = ContractState.Deployed;

   
  event State ( ContractState state );

   
  event Transfer ( address indexed from, address indexed to, uint value );


   

   
  mapping (address => uint) public balanceOf;

   
  uint public bountyTokens = 40000 * TOKEN_SCALE;

   
  uint public sellingPrice = 0;

   
  uint public buybackPrice = 0;

   
  uint public etherAccumulator = 0;

   
  uint public icoStartTime = ICO_START_TIME;

   
  address public trustedSender = address(0);


   

  uint8[4] private bonuses = [ uint8(15), uint8(10), uint8(5), uint8(3) ];   
  uint[4]  private staging = [ 1 weeks,   2 weeks,   3 weeks,  4 weeks ];    


   
  function PulsarToken() public
  {
     
  }


   

   
  function calcBonusPercent() public view returns (uint8) {
    uint8 _bonus = 0;
    uint _elapsed = now - icoStartTime;

    for (uint8 i = 0; i < staging.length; i++) {
      if (_elapsed <= staging[i]) {
          _bonus = bonuses[i];
          break;
      }
    }
    return _bonus;
  }

   
  function calcAmountWithBonus(uint token_value, uint8 bonus) public view returns (uint) {
    return  (token_value * (100 + bonus)) / 100;
  }

   
  function calcEthersToTokens(uint ether_value, uint8 bonus) public view returns (uint) {
    return calcAmountWithBonus(TOKEN_SCALE * ether_value/sellingPrice, bonus);
  }

   
  function calcTokensToEthers(uint token_value) public view returns (uint) {
      return (buybackPrice * token_value) / TOKEN_SCALE;
  }

   
  function _transfer(address _from, address _to, uint _value) internal
  {
    require(_to != address(0x0));                        
    require(_value > 0);                                 
    require(balanceOf[_from] >= _value);                 
    require(balanceOf[_to] + _value > balanceOf[_to]);   

    balanceOf[_from]  -= _value;                         
    balanceOf[_to]    += _value;                         

    Transfer(_from, _to, _value);                        
  }


   

   
  function getContractState() public view returns (uint8) {
    return uint8(contractState);
  }

   
  function getContractTokenBalance() public view returns (uint) {
    return balanceOf[this];
  }

   
  function getTokenBalance(address holder_address) public view returns (uint) {
    require(holder_address != address(0));
    return balanceOf[holder_address];
  }

   
  function getDistributedTokens() public view returns (uint) {
      return TOTAL_SUPPLY - balanceOf[this];
  }

   
  function getContractEtherBalance() public view returns (uint) {
    return this.balance;
  }

   
  function getEtherBalance(address holder_address) public view returns (uint) {
    require(holder_address != address(0));
    return holder_address.balance;
  }


   
  function invest() public payable
  {
    require(contractState == ContractState.ICOStarted);    
    require(now >= icoStartTime);                          
    require(msg.value >= MIN_ACCEPTED_VALUE);              

    uint8 _bonus  = calcBonusPercent();
    uint  _tokens = calcEthersToTokens(msg.value, _bonus);

    require(balanceOf[this] >= _tokens);                   

    _transfer(this, msg.sender, _tokens);                  

    etherAccumulator += msg.value;       
  }


   
  function () public payable {
    invest();
  }

   
  function buyback(uint token_value) public
  {
    require(contractState == ContractState.BuybackEnabled);    
    require(buybackPrice > 0);                                 
    require(token_value >= MIN_BUYBACK_VALUE);                 
    require(msg.sender != owner);                              

    uint _ethers = calcTokensToEthers(token_value);

     
    require(this.balance >= _ethers);

     
    _transfer(msg.sender, this, token_value);

     
    msg.sender.transfer(_ethers);
  }

   

   
  function setICOStartTime(uint start_time) onlyOwner external {
    icoStartTime = start_time;
  }

   
  function setSellingPrice(uint selling_price) onlyOwner public {
    require(selling_price != 0);
    sellingPrice = selling_price;
  }

   
  function startICO(uint selling_price) onlyOwner external {
    require(contractState == ContractState.Deployed);
    setSellingPrice(selling_price);

    balanceOf[this] = TOTAL_SUPPLY;

    contractState = ContractState.ICOStarted;
    State(contractState);
  }

   
  function stopICO() onlyOwner external {
    require(contractState == ContractState.ICOStarted);

    contractState = ContractState.ICOStopped;
    State(contractState);
  }

   
  function transferEthersToOwner(uint ether_value) onlyOwner external {
    require(this.balance >= ether_value);
    msg.sender.transfer(ether_value);
  }

   
  function setTrustedSender(address trusted_address) onlyOwner external {
    trustedSender = trusted_address;
  }

   
  function transferTokens(address recipient_address, uint token_value) external {
    require( (msg.sender == owner) || (msg.sender == trustedSender) );   
    require(contractState == ContractState.ICOStarted);                  
    require(now >= icoStartTime);                                        

    _transfer(this, recipient_address, token_value);
  }

   
  function grantBounty(address recipient_address, uint token_value) onlyOwner external {
    require((contractState == ContractState.ICOStarted) || (contractState == ContractState.ICOStopped));   
    require(bountyTokens >= token_value);   
    require(now >= icoStartTime);      

    _transfer(this, recipient_address, token_value);
    bountyTokens -= token_value;
  }

   
  function refundInvestment(address investor_address, uint ether_value) onlyOwner external {
    require((contractState == ContractState.ICOStopped) || (contractState == ContractState.BuybackPaused));    

    require(investor_address != owner);                    
    require(investor_address != address(this));            
    require(balanceOf[investor_address] > 0);              
    require(this.balance >= ether_value);                  

     
    _transfer(investor_address, this, balanceOf[investor_address]);

     
    investor_address.transfer(ether_value);
  }

   
  function setBuybackPrice(uint buyback_price) onlyOwner public {
    require(buyback_price > 0);
    buybackPrice = buyback_price;
  }

   
  function enableBuyback(uint buyback_price) onlyOwner external {
    require((contractState == ContractState.ICOStopped) || (contractState == ContractState.BuybackPaused));
    setBuybackPrice(buyback_price);

    contractState = ContractState.BuybackEnabled;
    State(contractState);
  }

   
  function pauseBuyback() onlyOwner external {
      require(contractState == ContractState.BuybackEnabled);

      contractState = ContractState.BuybackPaused;
      State(contractState);
  }

   
  function destroyContract() onlyOwner external {
      require(contractState == ContractState.BuybackPaused);

      contractState = ContractState.Destroyed;
      State(contractState);

      selfdestruct(owner);   
  }

}  