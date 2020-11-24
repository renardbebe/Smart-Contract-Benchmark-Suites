 

pragma solidity ^0.4.18;
 
 
contract SafeMath {

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

}
 
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
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
  if (newOwner != address(0)) {
      owner = newOwner;
  }
}

}


contract PPCToken is StandardToken,Ownable, SafeMath {

     
    string  public constant name = "PurpleCoin";
    string  public constant symbol = "PPC";
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    address public constant ethFundDeposit= 0x20D9053d3f7fccC069c9a8e7dDEf5374CD22b6C8;                          
    bool public emergencyFlag;                                       
    uint256 public fundingStartBlock;                               
    uint256 public fundingEndBlock;                                
    uint256 public constant minTokenPurchaseAmount= .008 ether;   
    uint256 public constant tokenPreSaleRate=800;     
    uint256 public constant tokenCrowdsaleRate=500;  
    uint256 public constant tokenCreationPreSaleCap =  10 * (10**6) * 10**decimals; 
    uint256 public constant tokenCreationCap =  100 * (10**6) * 10**decimals;       
    uint256 public constant preSaleBlockNumber = 169457;
    uint256 public finalBlockNumber =370711;


     
    event CreatePPC(address indexed _to, uint256 _value); 
    event Mint(address indexed _to,uint256 _value);      
     
    function PPCToken(){
      emergencyFlag = false;                              
      fundingStartBlock = block.number;                  
      fundingEndBlock=safeAdd(fundingStartBlock,finalBlockNumber);   
    }

     
    function createTokens() internal  {
      if (emergencyFlag) revert();                      
      if (block.number > fundingEndBlock) revert();    
      if (msg.value<minTokenPurchaseAmount)revert();   
      uint256 tokenExchangeRate=tokenRate();         
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); 
      totalSupply = safeAdd(totalSupply, tokens);             
      if(totalSupply>tokenCreationCap)revert();              
      balances[msg.sender] += tokens;                       
      forwardfunds();                                      
      CreatePPC(msg.sender, tokens);                       
    }

     
    function buyToken() payable external{
      createTokens();    
    }

     
    function tokenRate() internal returns (uint256 _tokenPrice){
       
      if(block.number<safeAdd(fundingStartBlock,preSaleBlockNumber)&&(totalSupply<tokenCreationPreSaleCap)){
          return tokenPreSaleRate;
        }else
            return tokenCrowdsaleRate;
    }

     
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
      if (emergencyFlag) revert();
      totalSupply = safeAdd(totalSupply,_amount); 
      if(totalSupply>tokenCreationCap)revert();
      balances[_to] +=_amount;                  
      Mint(_to, _amount);                      
      return true;
    }

     
    function changeEndBlock(uint256 _newBlock) external onlyOwner returns (uint256 _endblock )
    {    
        require(_newBlock > fundingStartBlock);
        fundingEndBlock = _newBlock;          
        return fundingEndBlock;
    }

     
    function drain() external onlyOwner {
        if (!ethFundDeposit.send(this.balance)) revert(); 
    }

    
    
     
    
    function forwardfunds() internal {
         if (!ethFundDeposit.send(this.balance)) revert();  
        
        
    }
    
     
    
    function emergencyToggle() external onlyOwner{
      emergencyFlag = !emergencyFlag;
    }

     
    function() payable {
      createTokens();

    }


}