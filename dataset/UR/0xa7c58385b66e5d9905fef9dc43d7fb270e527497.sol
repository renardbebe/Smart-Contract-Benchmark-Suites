 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract TokenWhitelist is Ownable {

    mapping(address => bool) private whitelist;

    event Whitelisted(address indexed wallet);
    event Dewhitelisted(address indexed wallet);

    function enableWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Invalid wallet");
        whitelist[_wallet] = true;
        emit Whitelisted(_wallet);
    }

    function disableWallet(address _wallet) public onlyOwner {
        whitelist[_wallet] = false;
        emit Dewhitelisted (_wallet);
    }
    
    function checkWhitelisted(address _wallet) public view returns (bool){
        return whitelist[_wallet];
    }
    
}