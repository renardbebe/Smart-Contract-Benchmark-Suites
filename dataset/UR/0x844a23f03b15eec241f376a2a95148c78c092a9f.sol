 

pragma solidity >=0.4.22 <0.6.0;


 
 
 
 
 
 
contract Ownable {
     
     
     
    event OwnershipTransfer (address previousOwner, address newOwner);
    
     
    address owner;
    
     
     
     
    constructor() public {
        owner = msg.sender;
    }

     
     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

     
     
     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
         
        require (_newOwner != address(0));
         
        address oldOwner = owner;
         
        owner = _newOwner;
         
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


 
 
 
interface VIP180 {
    function transfer (
        address to, 
        uint tokens
    ) external returns (bool success);

    function transferFrom (
        address from, 
        address to, 
        uint tokens
    ) external returns (bool success);
}


interface LockedTokenManager {    
    function lockFrom(
        address _tokenHolder, 
        address _tokenAddress, 
        uint _tokens, 
        uint _numberOfMonths
    ) external returns(bool);
    
    function transferFromAndLock(
        address _from,
        address _to,
        address _tokenAddress,
        uint _tokens,
        uint _numberOfMonths
    ) external returns (bool);
}


interface LinkDependency {
    function onLink(uint _oldUid, uint _newUid) external;
}


interface AacInterface {
    function ownerOf(uint _tokenId) external returns(address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function checkExists(uint _tokenId) external view returns(bool);
    
    function mint() external;
    function mintAndSend(address payable _to) external;
    function link(bytes7 _newUid, uint _aacId, bytes calldata _data) external;
    function linkExternalNft(uint _aacUid, address _externalAddress, uint _externalId) external;
}


contract SegmentedTransfer is Ownable {
    uint public percentageBurned = 50;
    uint public percentageLocked = 0;
    uint public percentageTransferredThenLocked = 0;
    uint public lockMonths = 24;
     
    LockedTokenManager public lockContract;

     
     
     
    modifier notZero(uint _param) {
        require(_param != 0);
        _;
    }
    
    function setLockContract(address _lockAddress) external onlyOwner {
        lockContract = LockedTokenManager(_lockAddress);
    }
    
     
     
     
     
     
     
     
     
    function setPercentages(uint _burned, uint _locked, uint _transferLocked, uint _lockMonths) 
        external 
        onlyOwner
    {
        require (_burned + _locked + _transferLocked <= 100);
        percentageBurned = _burned;
        percentageLocked = _locked;
        percentageTransferredThenLocked = _transferLocked;
        lockMonths = _lockMonths;
    }
    
     
     
     
    function segmentedTransfer(
        address _tokenContractAddress, 
        uint _totalTokens
    ) internal {
        uint tokensLeft = _totalTokens;
        uint amount;
         
        if (percentageBurned > 0) {
            amount = _totalTokens * percentageBurned / 100;
            VIP180(_tokenContractAddress).transferFrom(msg.sender, address(0), amount);
            tokensLeft -= amount;
        }
         
        if (percentageLocked > 0) {
            amount = _totalTokens * percentageLocked / 100;
            lockContract.lockFrom(msg.sender, _tokenContractAddress, lockMonths, amount);
            tokensLeft -= amount;
        }
         
        if (percentageTransferredThenLocked > 0) {
            amount = _totalTokens * percentageTransferredThenLocked / 100;
            lockContract.transferFromAndLock(msg.sender, address(this), _tokenContractAddress, lockMonths, amount);
            tokensLeft -= amount;
        }
         
        if (tokensLeft > 0) {
            VIP180(_tokenContractAddress).transferFrom(msg.sender, owner, tokensLeft);
        }
    }   
}


contract AacCreation is SegmentedTransfer {
    
     
    uint public priceToMint;
    
     
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;
    
     
    address public ehrtContractAddress;
    
    LinkDependency public coloredEhrtContract;
    LinkDependency public externalTokensContract;
    
    AacInterface public aacContract;
    
    
    
     
    mapping (address => bool) public allowedToLink;
    
    
     
     
     
     
    modifier canOperate(uint _uid) {
         
         
         
        address owner = aacContract.ownerOf(_uid);
        require (
            msg.sender == owner ||
            msg.sender == aacContract.getApproved(_uid) ||
            aacContract.isApprovedForAll(owner, msg.sender),
            "Not authorized to operate for this AAC"
        );
        _;
    }
    
     
     
     
     
    function updateAacContract(address _newAddress) external onlyOwner {
        aacContract = AacInterface(_newAddress);
    }

     
     
     
     
     
    function updateEhrtContractAddress(address _newAddress) external onlyOwner {
        ehrtContractAddress = _newAddress;
    }
    
     
     
     
     
     
    function updateColoredEhrtContractAddress(address _newAddress) external onlyOwner {
        coloredEhrtContract = LinkDependency(_newAddress);
    }
    
     
     
     
     
     
    function updateExternalTokensContractAddress(address _newAddress) external onlyOwner {
        externalTokensContract = LinkDependency(_newAddress);
    }

     
     
     
     
     
    function changeAacPrice(uint _newPrice) external onlyOwner {
        priceToMint = _newPrice;
    }

     
     
     
     
     
    function whitelistLinker(address _linker, bool _isAllowed) external onlyOwner {
        allowedToLink[_linker] = _isAllowed;
    }
    
     
     
     
     
     
     
     
    function mint() external {
        segmentedTransfer(ehrtContractAddress, priceToMint);

        aacContract.mintAndSend(msg.sender);
    }

     
     
     
     
     
     
     
     
    function mintAndSend(address payable _to) external {
        segmentedTransfer(ehrtContractAddress, priceToMint);
        
        aacContract.mintAndSend(_to);
    }

     
     
     
     
     
     
     
     
     
     
     
    function link(
        bytes7 _newUid, 
        uint _currentUid, 
        bytes calldata _data
    ) external canOperate(_currentUid) {
        require (allowedToLink[msg.sender]);
         
         
        require (_currentUid > UID_MAX);
         
        require (_newUid > 0 && uint56(_newUid) < UID_MAX);
         
        require (aacContract.checkExists(_currentUid) == false);
        
        aacContract.link(_newUid, _currentUid, _data);
        
        coloredEhrtContract.onLink(_currentUid, uint(uint56(_newUid)));
        externalTokensContract.onLink(_currentUid, uint(uint56(_newUid)));
    }
}