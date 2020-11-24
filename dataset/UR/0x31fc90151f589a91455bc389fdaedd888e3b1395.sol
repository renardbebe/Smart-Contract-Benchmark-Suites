 

 

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

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

 

 
contract FreezeRule is IRule, Authority {

  mapping(address => uint256) freezer;
  uint256 allFreezedUntil;

   
  function isFrozen() public view returns (bool) {
     
    return allFreezedUntil > now ;
  }

   
  function isAddressFrozen(address _address) public view returns (bool) {
     
    return freezer[_address] > now;
  }

   
  function freezeAddress(address _address, uint256 _until)
    public onlyAuthority returns (bool)
  {
    freezer[_address] = _until;
    emit Freeze(_address, _until);
  }

   
  function freezeManyAddresses(address[] _addresses, uint256 _until)
    public onlyAuthority returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      freezer[_addresses[i]] = _until;
      emit Freeze(_addresses[i], _until);
    }
  }

   
  function freezeAll(uint256 _until) public
    onlyAuthority returns (bool)
  {
    allFreezedUntil = _until;
    emit FreezeAll(_until);
  }

   
  function isAddressValid(address _address) public view returns (bool) {
    return !isFrozen() && !isAddressFrozen(_address);
  }

    
  function isTransferValid(address _from, address _to, uint256  )
    public view returns (bool)
  {
    return !isFrozen() && (!isAddressFrozen(_from) && !isAddressFrozen(_to));
  }

  event FreezeAll(uint256 until);
  event Freeze(address _address, uint256 until);
}