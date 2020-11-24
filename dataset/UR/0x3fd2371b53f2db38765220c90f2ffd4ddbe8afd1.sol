 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

 

 
contract MonethaUsersClaimStorage is Contactable {

    string constant VERSION = "0.1";
    
     
    mapping (address => uint256) public claimedTokens;

    event UpdatedClaim(address indexed _userAddress, uint256 _claimedTokens, bool _isDeleted);
    event DeletedClaim(address indexed _userAddress, uint256 _unclaimedTokens, bool _isDeleted);

     
    function updateUserClaim(address _userAddress, uint256 _tokens)
        external onlyOwner returns (bool)
    {
        claimedTokens[_userAddress] = claimedTokens[_userAddress] + _tokens;

        emit UpdatedClaim(_userAddress, _tokens, false);
        
        return true;
    }
    
     
    function updateUserClaimInBulk(address[] _userAddresses, uint256[] _tokens)
        external onlyOwner returns (bool)
    {
        require(_userAddresses.length == _tokens.length);

        for (uint16 i = 0; i < _userAddresses.length; i++) {
            claimedTokens[_userAddresses[i]] = claimedTokens[_userAddresses[i]] + _tokens[i];

            emit UpdatedClaim(_userAddresses[i], _tokens[i], false);
        }

        return true;
    }

     
    function deleteUserClaim(address _userAddress)
        external onlyOwner returns (bool)
    {
        delete claimedTokens[_userAddress];

        emit DeletedClaim(_userAddress, 0, true);

        return true;
    }

     
    function deleteUserClaimInBulk(address[] _userAddresses)
        external onlyOwner returns (bool)
    {
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            delete claimedTokens[_userAddresses[i]];

            emit DeletedClaim(_userAddresses[i], 0, true);
        }

        return true;
    }
}

 

 
contract MonethaUsersClaimHandler is Contactable {

    string constant VERSION = "0.1";
    
    MonethaUsersClaimStorage public storageContract;

    event StorageContractOwnerChanged(address indexed _newOwner);

    constructor(address _storageAddr) public {
        storageContract = MonethaUsersClaimStorage(_storageAddr);
    }

     
    function claimTokens(address _monethaUser, uint256 _tokens) external onlyOwner {
        require(storageContract.updateUserClaim(_monethaUser, _tokens));
    }

     
    function claimTokensInBulk(address[] _monethaUsers, uint256[] _tokens) external onlyOwner {
        require(storageContract.updateUserClaimInBulk(_monethaUsers, _tokens));
    }

     
    function deleteAccount(address _monethaUser) external onlyOwner {
        require(storageContract.deleteUserClaim(_monethaUser));
    }

     
    function deleteAccountsInBulk(address[] _monethaUsers) external onlyOwner {
        require(storageContract.deleteUserClaimInBulk(_monethaUsers));
    }

     
    function changeOwnerOfMonethaUsersClaimStorage(address _newOwner) external onlyOwner {
        storageContract.transferOwnership(_newOwner);

        emit StorageContractOwnerChanged(_newOwner);
    }
}