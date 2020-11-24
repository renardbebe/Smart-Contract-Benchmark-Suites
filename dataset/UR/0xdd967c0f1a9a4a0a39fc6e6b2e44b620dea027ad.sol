 

pragma solidity ^0.4.15;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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



interface Token {
    
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}




contract Crowdsale is Ownable {
    
    using SafeMath for uint256;

    Token public token;

    uint256 public RATE = 50000;  
    uint256 public START;
    uint256 public minETH = 100 finney;

    uint256 public constant initialTokens =  4000000000 * 10**18;  
    bool public isFunding = true;
    uint256 public raisedAmount = 0;

    event BoughtTokens(address indexed to, uint256 value);

    modifier whenSaleIsActive() {
     
        assert(isActive());
        _;
    }

    function Crowdsale(address _tokenAddr, uint256 _start) public {
        require(_tokenAddr != 0);
        token = Token(_tokenAddr);
        START = _start;
    }
  
    
    function changeSaleStatus (bool _isFunding) external onlyOwner {
       isFunding = _isFunding;
       
    }
    
    function changeRate (uint256 _RATE) external onlyOwner {
       RATE = _RATE;
    }

    function isActive() public constant returns (bool) {
        return (
            isFunding == true &&
            now >= START &&  
            now <= START.add(92 days)
        );
    }

    


    function () public payable {
        
        if (now >= START && now < START.add(31 days)) {
            RATE = 50000;   
            buyTokens();
        } 
        else {
            RATE = 40000;
            buyTokens();  
        }            
    }
      
  
    function buyTokens() public payable whenSaleIsActive {
        
         
        require(msg.value >= minETH);
        
         
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);

        BoughtTokens(msg.sender, tokens);
        raisedAmount = raisedAmount.add(msg.value);
        token.transfer(msg.sender, tokens);
        owner.transfer(msg.value);
    }
    
    function tokensAvailable() public constant returns (uint256) {
        return token.balanceOf(this);
    }
    
    
    function burnRemaining() public onlyOwner {
        
        uint256 burnThis = token.balanceOf(this);
        token.transfer(address(0), burnThis);
    }
    


    function destroy() public onlyOwner {
    
         
        uint256 balance = token.balanceOf(this);
        assert(balance > 0);
        token.transfer(owner, balance);

         
        selfdestruct(owner);
    }

}