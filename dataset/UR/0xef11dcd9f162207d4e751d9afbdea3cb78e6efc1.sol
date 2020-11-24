 

pragma solidity 0.4.19;
 
interface ERC223 {

    function totalSupply() public view returns (uint);
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function balanceOf(address _owner) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint indexed _value, bytes _data);
}

 
interface ERC223ReceivingContract { 
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
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



 
contract Vesting is Ownable, ERC223ReceivingContract {
    address public token;
    uint public totalTokens = 0;
    uint public constant FIRST_UNLOCK = 1531612800;  
    uint public constant TOTAL_TOKENS = 100000000 * (uint(10) ** 18);  
    bool public tokenReceived = false;

    event Withdraw(address _to, uint _value);

     
    function Vesting(address _token) public Ownable() {
        token = _token;
    }

     
    function tokenFallback(address, uint _value, bytes) public {
        require(!tokenReceived);
        require(msg.sender == token);
        require(_value == TOTAL_TOKENS);
        tokenReceived = true;
    }

     
    function withdraw(uint _amount) public onlyOwner {
        uint availableTokens = ERC223(token).balanceOf(this) - lockedAmount();
        require(_amount <= availableTokens);
        ERC223(token).transfer(msg.sender, _amount);
        Withdraw(msg.sender, _amount);
    }

     
    function withdrawAll() public onlyOwner {
        uint availableTokens = ERC223(token).balanceOf(this) - lockedAmount();
        ERC223(token).transfer(msg.sender, availableTokens);
        Withdraw(msg.sender, availableTokens);
    }
    
     
    function lockedAmount() internal view returns (uint) {
        if (now < FIRST_UNLOCK) {
            return TOTAL_TOKENS;  
        }

        uint quarters = (now - FIRST_UNLOCK) / 0.25 years;  
        uint effectiveQuarters = quarters <= 12 ? quarters : 12;  
        uint locked = TOTAL_TOKENS * (7500 - effectiveQuarters * 625) / 10000;  

        return locked;
    }
}