 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




contract KyberContirbutorWhitelist is Ownable {
    mapping(address=>uint) addressCap;
    
    function KyberContirbutorWhitelist() {}
    
    event ListAddress( address _user, uint _cap, uint _time );
    
     
     
    function listAddress( address _user, uint _cap ) onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }
    
    function getCap( address _user ) constant returns(uint) {
        return addressCap[_user];
    }
}