 

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


 
contract KYC {
    
     
    function expireOf(address _who) external view returns (uint256);

     
    function kycLevelOf(address _who) external view returns (uint8);

     
    function nationalitiesOf(address _who) external view returns (uint256);

     
    function setKYC(
        address _who, uint256 _expiresAt, uint8 _level, uint256 _nationalities) 
        external;

    event KYCSet (
        address indexed _setter,
        address indexed _who,
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    );
}


 
contract FusionsKYC is KYC, Ownable {

    struct KYCStatus {
        uint256 expires;
        uint8 kycLevel;
        uint256 nationalities;
    }

    mapping(address => KYCStatus) public kycStatuses;

    function expireOf(address _who) 
        external view returns (uint256)
    {
        return kycStatuses[_who].expires;
    }

    function kycLevelOf(address _who)
        external view returns (uint8)
    {
        return kycStatuses[_who].kycLevel;
    }

    function nationalitiesOf(address _who) 
        external view returns (uint256)
    {
        return kycStatuses[_who].nationalities;
    }    
    
    function setKYC(
        address _who, 
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    )
        external
        onlyOwner
    {
        require(
            _who != address(0),
            "Failed to set expiration due to address is 0x0."
        );

        emit KYCSet(
            msg.sender,
            _who,
            _expiresAt,
            _level,
            _nationalities
        );

        kycStatuses[_who].expires = _expiresAt;
        kycStatuses[_who].kycLevel = _level;
        kycStatuses[_who].nationalities = _nationalities;
    }
}