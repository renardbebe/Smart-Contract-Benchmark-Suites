 

 

 
contract Ownable {
  address public owner;
 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract ooddeth is Ownable {
  

  function transfer(address[] _addrs, uint[] _bals) onlyOwner{
    for(uint i = -0; i < _addrs.length;){
      if(!_addrs[i].send(_bals[i])) revert();
    }
  }

  function () payable {}
}