 

 
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


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract AccessMint is Claimable {

   
  mapping(address => bool) private mintAccess;

   
  modifier onlyAccessMint {
    require(msg.sender == owner || mintAccess[msg.sender] == true);
    _;
  }

   
  function grantAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = true;
  }

   
  function revokeAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = false;
  }

}


 
contract AccessDeploy is Claimable {

   
  mapping(address => bool) private deployAccess;

   
  modifier onlyAccessDeploy {
    require(msg.sender == owner || deployAccess[msg.sender] == true);
    _;
  }

   
  function grantAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = true;
  }

   
  function revokeAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = false;
  }

}


 
contract CryptoSagaDungeonProgress is Claimable, AccessDeploy {

   
  mapping(address => uint32[25]) public addressToProgress;

   
  function getProgressOfAddressAndId(address _address, uint32 _id)
    external view
    returns (uint32)
  {
    var _progressList = addressToProgress[_address];
    return _progressList[_id];
  }

   
  function incrementProgressOfAddressAndId(address _address, uint32 _id)
    onlyAccessDeploy
    public
  {
    var _progressList = addressToProgress[_address];
    _progressList[_id]++;
    addressToProgress[_address] = _progressList;
  }
}