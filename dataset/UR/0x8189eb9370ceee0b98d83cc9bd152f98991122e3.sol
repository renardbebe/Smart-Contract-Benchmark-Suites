 

pragma solidity ^0.5.11;

interface ERC20 {

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Ownable {
  address payable public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract Mortal is Ownable {
     
    function kill() public onlyOwner{
        owner.transfer(address(this).balance);
        selfdestruct(owner);
    }
}



contract Cryptoman is Mortal{

     
    function deposit() public payable {
    }

     
    function withdraw(uint amount, address payable receiver) public onlyOwner {
      require(address(this).balance >= amount, "insufficient balance");
      receiver.transfer(amount);
    }
    
     
    function withdrawTokens(address tokenAddress, uint amount, address payable receiver) public payable onlyOwner {
      ERC20 token = ERC20(tokenAddress);
      require(token.balanceOf(address(this))>=amount,"insufficient funds");
      token.transfer(receiver, amount);
    }


}