 

pragma solidity 0.4.18;

 

 
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract AirdropperERC20 is Ownable {

  function multiSend(address _tokenAddr, address[] recipients, uint256[] amounts) external onlyOwner {
    require(recipients.length == amounts.length);

    for (uint256 i = 0; i < recipients.length; i++) {
      ERC20(_tokenAddr).transfer(recipients[i], amounts[i]);
    }
  }

  function withdraw (address _tokenAddr) external onlyOwner {
    ERC20 token = ERC20(_tokenAddr);

    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }
}