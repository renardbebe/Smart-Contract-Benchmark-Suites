 

pragma solidity ^0.4.11;




 
 
 
 

contract MPY {

    string public constant name = "MatchPay Token";
    string public constant symbol = "MPY";
    uint256 public constant decimals = 18;

    address owner;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public constant tokenExchangeRate = 10;  
    uint256 public maxCap = 30 * (10**3) * (10**decimals);  
    uint256 public totalSupply;  
    uint256 public minCap = 10 * (10**2) * (10**decimals);  
    uint256 public ownerTokens = 3 * (10**2) * (10**decimals);

    bool public isFinalized = false;


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


     
    event MPYCreation(address indexed _owner, uint256 _value);


     
    event MPYRefund(address indexed _owner, uint256 _value);


     


     
    modifier is_live() { require(block.number >= fundingStartBlock && block.number <= fundingEndBlock); _; }


     
    modifier only_owner(address _who) { require(_who == owner); _; }


     


     
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

     
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

     
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }


     


     
    function MPY(
      uint256 _fundingStartBlock,
      uint256 _fundingEndBlock
    ) {

        owner = msg.sender;

        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;

    }


     
     
    function balanceOf(address _owner) constant returns (uint256) {
      return balances[_owner];
    }


     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
      if (balances[msg.sender] >= _amount
          && _amount > 0
          && balances[_to] + _amount > balances[_to]) {

              balances[msg.sender] -= _amount;
              balances[_to] += _amount;

              Transfer(msg.sender, _to, _amount);

              return true;
      } else {
          return false;
      }
    }


     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
      if (balances[_from] >= _amount
          && allowed[_from][msg.sender] >= _amount
          && _amount > 0
          && balances[_to] + _amount > balances[_to]) {

              balances[_from] -= _amount;
              allowed[_from][msg.sender] -= _amount;
              balances[_to] += _amount;

              Transfer(_from, _to, _amount);

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


     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }


     


    function getStats() constant returns (uint256, uint256, uint256, uint256) {
        return (minCap, maxCap, totalSupply, fundingEndBlock);
    }

    function getSupply() constant returns (uint256) {
        return totalSupply;
    }


     


     
    function() is_live() payable {
        if (msg.value == 0) revert();
        if (isFinalized) revert();

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);    
        uint256 checkedSupply = safeAdd(totalSupply, tokens);       

        if (maxCap < checkedSupply) revert();                          

        totalSupply = checkedSupply;                                
        balances[msg.sender] += tokens;                             
        MPYCreation(msg.sender, tokens);                            
    }


     
    function emergencyPay() external payable {}


     
    function finalize() external {
        if (msg.sender != owner) revert();                                          
        if (totalSupply < minCap) revert();                                         
        if (block.number <= fundingEndBlock && totalSupply < maxCap) revert();      

        if (!owner.send(this.balance)) revert();                                    

        balances[owner] += ownerTokens;
        totalSupply += ownerTokens;

        isFinalized = true;                                                      
    }


     
    function refund() external {
        if (isFinalized) revert();                                
        if (block.number <= fundingEndBlock) revert();            
        if (totalSupply >= minCap) revert();                      
        if (msg.sender == owner) revert();                        

        uint256 mpyVal = balances[msg.sender];                 
        if (mpyVal == 0) revert();                                

        balances[msg.sender] = 0;                              
        totalSupply = safeSubtract(totalSupply, mpyVal);       
        uint256 ethVal = mpyVal / tokenExchangeRate;           
        MPYRefund(msg.sender, ethVal);                         

        if (!msg.sender.send(ethVal)) revert();                   
    }
}