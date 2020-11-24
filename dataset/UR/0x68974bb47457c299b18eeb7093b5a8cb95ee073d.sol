 

pragma solidity ^0.4.18;

 
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

interface itoken {
    function transferMultiAddressFrom(address _from, address[] _toMulti, uint256[] _values) public returns (bool);
}

contract AirsendGifts is Ownable {
     

     
     
     
     
     
     
     
     
    
    function multiSend(address _tokenAddr, address _tokenOwner, address[] _destAddrs, uint256[] _values) onlyOwner public returns (bool) {
        assert(_destAddrs.length == _values.length);

        return itoken(_tokenAddr).transferMultiAddressFrom(_tokenOwner, _destAddrs, _values);
    }
}