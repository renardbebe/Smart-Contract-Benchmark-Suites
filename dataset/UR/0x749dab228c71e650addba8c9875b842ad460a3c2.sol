 

pragma solidity ^0.4.13;


 
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

contract KyberContributorWhitelist is Ownable {
     
    uint public slackUsersCap = 7;
    mapping(address=>uint) public addressCap;

    function KyberContributorWhitelist() {}

    event ListAddress( address _user, uint _cap, uint _time );

     
     
    function listAddress( address _user, uint _cap ) onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }

     
    function listAddresses( address[] _users, uint[] _cap ) onlyOwner {
        require(_users.length == _cap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _cap[i] );
        }
    }

    function setSlackUsersCap( uint _cap ) onlyOwner {
        slackUsersCap = _cap;
    }

    function getCap( address _user ) constant returns(uint) {
        uint cap = addressCap[_user];

        if( cap == 1 ) return slackUsersCap;
        else return cap;
    }

    function destroy() onlyOwner {
        selfdestruct(owner);
    }
}