 

contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
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

contract Airdrop is Ownable {
    
  function distributeBulk(ERC20 token, address[] recipients, uint256[] values) onlyOwner public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
  
  function distribute(ERC20 token, address recipient, uint256 value) onlyOwner public {
      token.transfer(recipient, value);
  }
}