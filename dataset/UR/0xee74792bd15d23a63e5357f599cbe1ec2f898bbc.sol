 

pragma solidity ^0.4.11;

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


contract IndorsePreSale is SafeMath{
     
    address public ethFundDeposit = "0x1c82ee5b828455F870eb2998f2c9b6Cc2d52a5F6";                              
    address public owner;                                        
    mapping (address => uint256) public whiteList;

     
    bool public isFinalized;                                     
    uint256 public constant maxLimit =  14000 ether;             
    uint256 public constant minRequired = 100 ether;             
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    
     
    event Contribution(address indexed _to, uint256 _value);
    
    modifier onlyOwner() {
      require (msg.sender == owner);
      _;
    }

     
    function IndorsePreSale() {
      isFinalized = false;                                       
      owner = msg.sender;
      totalSupply = 0;
    }

     
    function() payable {           
      uint256 checkedSupply = safeAdd(totalSupply, msg.value);
      require (msg.value >= minRequired);                         
      require (!isFinalized);                                     
      require (checkedSupply <= maxLimit);
      require (whiteList[msg.sender] == 1);
      balances[msg.sender] = safeAdd(balances[msg.sender], msg.value);
      
      totalSupply = safeAdd(totalSupply, msg.value);
      Contribution(msg.sender, msg.value);
      ethFundDeposit.transfer(this.balance);                      
    }
    
     
    function setWhiteList(address _whitelisted) onlyOwner {
      whiteList[_whitelisted] = 1;
    }

     
    function removeWhiteList(address _whitelisted) onlyOwner {
      whiteList[_whitelisted] = 0;
    }

     
    function finalize() external onlyOwner {
      require (!isFinalized);
       
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);                      
    }
}