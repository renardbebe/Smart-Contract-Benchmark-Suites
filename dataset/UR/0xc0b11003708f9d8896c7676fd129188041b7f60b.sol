 

pragma solidity ^0.4.25;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Whitelist is Ownable {

  address public opsAddress;
  mapping(address => uint8) public whitelist;

  event WhitelistUpdated(address indexed _account, uint8 _phase);

  function isWhitelisted(address _account) public constant returns (bool) {
      return whitelist[_account] == 1;
  }

   
function updateWhitelist(
    address _account,
    uint8 _phase) public
    returns (bool)
{
    require(_account != address(0));
    require(_phase <= 1);
    require(isOps(msg.sender));

    whitelist[_account] = _phase;

    emit WhitelistUpdated(_account, _phase);

    return true;
}


   
   
  function isOwner(
      address _address)
      internal
      view
      returns (bool)
  {
      return (_address == owner);
  }
   
  function isOps(
      address _address)
      internal
      view
      returns (bool)
  {
      return (opsAddress != address(0) && _address == opsAddress) || isOwner(_address);
  }

   

   
  function setOpsAddress(
      address _opsAddress)
      external
      onlyOwner
      returns (bool)
  {
      require(_opsAddress != owner);
      require(_opsAddress != address(this));
      require(_opsAddress != address(0));

      opsAddress = _opsAddress;

      return true;
  }

}