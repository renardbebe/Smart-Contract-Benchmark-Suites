 

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

 

 
contract BRDCrowdsaleAuthorizer is Ownable {
   
  mapping (address => bool) internal authorizedAccounts;
   
  mapping (address => bool) internal authorizers;

   
  event Authorized(address indexed _to);

   
   
  function addAuthorizer(address _newAuthorizer) onlyOwnerOrAuthorizer public {
     
    authorizers[_newAuthorizer] = true;
  }

   
   
  function removeAuthorizer(address _bannedAuthorizer) onlyOwnerOrAuthorizer public {
     
    require(authorizers[_bannedAuthorizer]);
     
    delete authorizers[_bannedAuthorizer];
  }

   
  function authorizeAccount(address _newAccount) onlyOwnerOrAuthorizer public {
    if (!authorizedAccounts[_newAccount]) {
       
      authorizedAccounts[_newAccount] = true;
       
      Authorized(_newAccount);
    }
  }

   
  function isAuthorizer(address _account) constant public returns (bool _isAuthorizer) {
    return msg.sender == owner || authorizers[_account] == true;
  }

   
  function isAuthorized(address _account) constant public returns (bool _authorized) {
    return authorizedAccounts[_account] == true;
  }

   
  modifier onlyOwnerOrAuthorizer() {
    require(msg.sender == owner || authorizers[msg.sender]);
    _;
  }
}