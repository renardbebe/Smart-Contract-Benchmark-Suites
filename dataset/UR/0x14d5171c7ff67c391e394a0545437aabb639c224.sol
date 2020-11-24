 

pragma solidity ^0.4.0;

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ElecWhitelist is Ownable {
     
     
     
    uint public communityusersCap = 1067*(10**15);
    mapping(address=>uint) public addressCap;

    function ElecWhitelist() public {}

    event ListAddress( address _user, uint _cap, uint _time );

     
     
    function listAddress( address _user, uint _cap ) public onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }

     
    function listAddresses( address[] _users, uint[] _cap ) public onlyOwner {
        require(_users.length == _cap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _cap[i] );
        }
    }

    function setUsersCap( uint _cap ) public  onlyOwner {
        communityusersCap = _cap;
    }

    function getCap( address _user ) public constant returns(uint) {
        uint cap = addressCap[_user];
        if( cap == 1 ) return communityusersCap;
        else return cap;
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}