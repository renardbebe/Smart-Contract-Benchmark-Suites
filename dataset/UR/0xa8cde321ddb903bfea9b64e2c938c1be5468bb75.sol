 

pragma solidity ^0.4.11;
    

  contract ERC20Interface {
       
      function totalSupply() constant returns (uint256 totalSupply);
   
       
      function balanceOf(address _owner) constant returns (uint256 balance);
   
       
      function transfer(address _to, uint256 _value) returns (bool success);
   
       
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
   
       
       
       
      function approve(address _spender, uint256 _value) returns (bool success);
   
       
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
   
       
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
       
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }
   
  contract ImmutableShares is ERC20Interface {
      
     string public constant symbol = "CSH";
      string public constant name = "Cryptex Shares";
      uint8 public constant decimals = 0;
      uint256 _totalSupply = 53000000;
      uint256 public totalSupply;
      uint256 public TotalDividendsPerShare;
      address public fallbackAccount = 0x0099F456e88E0BF635f6B2733e4228a2b5749675; 

       
      address public owner;
   
       
      mapping(address => uint256) public balances;
   
       
      mapping(address => mapping (address => uint256)) allowed;

       
      mapping (address => uint256) public dividendsPaidPerShare;
   
       
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }
   
       
      function ImmutableShares() {
          owner = msg.sender;
          balances[owner] = _totalSupply;
	      totalSupply = _totalSupply;   
      }


function isContract(address addr) returns (bool) {
  uint size;
  assembly { size := extcodesize(addr) }
  return size > 0;
  addr=addr;
}

  function changeFallbackAccount(address fallbackAccount_) {
    if (msg.sender != owner) throw;
    fallbackAccount = fallbackAccount_;
  }

 
   function withdrawMyDividend() payable {
   bool IsContract = isContract(msg.sender);
   if((balances[msg.sender] > 0) && (!IsContract)){
     uint256 AmountToSendPerShare = TotalDividendsPerShare - dividendsPaidPerShare[msg.sender];
     dividendsPaidPerShare[msg.sender] = TotalDividendsPerShare;
  if((balances[msg.sender]*AmountToSendPerShare) > 0){
     msg.sender.transfer(balances[msg.sender]*AmountToSendPerShare);}
}

if((balances[msg.sender] > 0) && (IsContract)){
     uint256 AmountToSendPerShareEx = TotalDividendsPerShare - dividendsPaidPerShare[msg.sender];
     dividendsPaidPerShare[msg.sender] = TotalDividendsPerShare;
     if((balances[msg.sender]*AmountToSendPerShareEx) > 0){
     fallbackAccount.transfer(balances[msg.sender]*AmountToSendPerShareEx);}
}

   }

 
  function payReceiver(address ReceiverAddress) payable {
   if(balances[ReceiverAddress] > 0){
     uint256 AmountToSendPerShare = TotalDividendsPerShare - dividendsPaidPerShare[ReceiverAddress];
     dividendsPaidPerShare[ReceiverAddress] = TotalDividendsPerShare;
     if((balances[ReceiverAddress]*AmountToSendPerShare) > 0){
     ReceiverAddress.transfer(balances[ReceiverAddress]*AmountToSendPerShare);}
}

}
   
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }
   
       
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }
   
       
      function transfer(address _to, uint256 _amount) returns (bool success) {
          if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
       
       withdrawMyDividend();
       payReceiver(_to);

              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(msg.sender, _to, _amount);

       dividendsPaidPerShare[_to] = TotalDividendsPerShare;

              return true;

          } else {
              return false;
          }
      }
   
       
       
       
       
       
       
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
     ) returns (bool success) {
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {

       withdrawMyDividend();
       payReceiver(_to);

             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);

       dividendsPaidPerShare[_from] = TotalDividendsPerShare;     
       dividendsPaidPerShare[_to] = TotalDividendsPerShare;

             return true;
         } else {
             return false;
         }
     }
  
      
      
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }

    
   function () payable {
   if(msg.value != 5300000000000000000) throw;  
   TotalDividendsPerShare += (msg.value/totalSupply);
   }

 }