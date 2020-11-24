 

pragma solidity ^0.4.16;




 
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







contract MultiTransfer is Ownable {
    ERC20 public gctAddress;

    function MultiTransfer(address gct) public {
        gctAddress = ERC20(gct);
    }


    function transfer(address[] to, uint[] value) public onlyOwner {
        require(to.length == value.length);

        for (uint i = 0; i < to.length; i++) {
            gctAddress.transferFrom(owner, to[i], value[i]);
        }
    }
}