 

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Raindrop is Ownable {

   
  event AuthenticateEvent(
      uint partnerId,
      address indexed from,
      uint value
      );

   
  event WhitelistEvent(
      uint partnerId,
      address target,
      bool whitelist
      );

  address public hydroContract = 0x0;

  mapping (uint => mapping (address => bool)) public whitelist;
  mapping (uint => mapping (address => partnerValues)) public partnerMap;
  mapping (uint => mapping (address => hydroValues)) public hydroPartnerMap;

  struct partnerValues {
      uint value;
      uint challenge;
  }

  struct hydroValues {
      uint value;
      uint timestamp;
  }

  function setHydroContractAddress(address _addr) public onlyOwner {
      hydroContract = _addr;
  }

   
  function whitelistAddress(address _target, bool _whitelistBool, uint _partnerId) public onlyOwner {
      whitelist[_partnerId][_target] = _whitelistBool;
      emit WhitelistEvent(_partnerId, _target, _whitelistBool);
  }

   
  function authenticate(address _sender, uint _value, uint _challenge, uint _partnerId) public {
      require(msg.sender == hydroContract);
      require(whitelist[_partnerId][_sender]);          
      require(hydroPartnerMap[_partnerId][_sender].value == _value);
      updatePartnerMap(_sender, _value, _challenge, _partnerId);
      emit AuthenticateEvent(_partnerId, _sender, _value);
  }

  function checkForValidChallenge(address _sender, uint _partnerId) public view returns (uint value){
      if (hydroPartnerMap[_partnerId][_sender].timestamp > block.timestamp){
          return hydroPartnerMap[_partnerId][_sender].value;
      }
      return 1;
  }

   
  function updateHydroMap(address _sender, uint _value, uint _partnerId) public onlyOwner {
      hydroPartnerMap[_partnerId][_sender].value = _value;
      hydroPartnerMap[_partnerId][_sender].timestamp = block.timestamp + 1 days;
  }

   
  function validateAuthentication(address _sender, uint _challenge, uint _partnerId) public constant returns (bool _isValid) {
      if (partnerMap[_partnerId][_sender].value == hydroPartnerMap[_partnerId][_sender].value
      && block.timestamp < hydroPartnerMap[_partnerId][_sender].timestamp
      && partnerMap[_partnerId][_sender].challenge == _challenge) {
          return true;
      }
      return false;
  }

   
  function updatePartnerMap(address _sender, uint _value, uint _challenge, uint _partnerId) internal {
      partnerMap[_partnerId][_sender].value = _value;
      partnerMap[_partnerId][_sender].challenge = _challenge;
  }

}