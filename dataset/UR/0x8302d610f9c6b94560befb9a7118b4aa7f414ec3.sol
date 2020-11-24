 

pragma solidity ^0.4.18;
 


 
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


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract GasFaucet is Owned {
    using SafeMath for uint256;

    address public faucetTokenAddress;
    uint256 public priceInWeiPerSatoshi;

    event Dispense(address indexed destination, uint256 sendAmount);

    constructor() public {
         
         
         
        faucetTokenAddress = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

         
         
        priceInWeiPerSatoshi = 0;
    }

     
     
     
     
     
     
    function dispense(address destination) public {
        uint256 sendAmount = calculateDispensedTokensForGasPrice(tx.gasprice);
        require(tokenBalance() > sendAmount);

        ERC20Interface(faucetTokenAddress).transfer(destination, sendAmount);

        emit Dispense(destination, sendAmount);
    }
    
     
     
     
    function calculateDispensedTokensForGasPrice(uint256 gasprice) public view returns (uint256) {
        if(priceInWeiPerSatoshi == 0){ 
            return 0; 
        }
        return gasprice.div(priceInWeiPerSatoshi);
    }
    
     
     
     
    function tokenBalance() public view returns (uint)  {
        return ERC20Interface(faucetTokenAddress).balanceOf(this);
    }
    
     
     
     
    function getWeiPerSatoshi() public view returns (uint256) {
        return priceInWeiPerSatoshi;
    }
    
     
     
     
    function setWeiPerSatoshi(uint256 price) public onlyOwner {
        priceInWeiPerSatoshi = price;
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function withdrawEth(uint256 amount) public onlyOwner {
        require(amount < address(this).balance);
        owner.transfer(amount);
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner {
        
         
         
         
         
         
         
         

        ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}