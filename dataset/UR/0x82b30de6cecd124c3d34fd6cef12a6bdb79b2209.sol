 

pragma solidity 0.4.24;

 

interface FreeDnaCardRepositoryInterface {
    function airdrop(address to, uint256 animalId) external;

    function giveaway(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    external;
}

 

 
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

 

contract Restricted is Ownable {
    mapping(address => bool) private addressIsAdmin;
    bool private isActive = true;

    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] || msg.sender == owner);
        _;
    }

    modifier contractIsActive() {
        require(isActive);
        _;
    }

    function addAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = false;
    }

    function pauseContract() public onlyOwner {
        isActive = false;
    }

    function activateContract() public onlyOwner {
        isActive = true;
    }
}

 

contract GameData {
    struct Country {       
        bytes2 isoCode;
        uint8 animalsCount;
        uint256[3] animalIds;
    }

    struct Animal {
        bool isSold;
        uint256 currentValue;
        uint8 rarity;  

        bytes32 name;         
        uint256 countryId;  

    }

    struct Dna {
        uint256 animalId; 
        uint8 effectiveness;  
    }    
}

 

contract FreeDnaCardRepository is FreeDnaCardRepositoryInterface, GameData, Restricted {
    event NewAirdrop(
        address to,
        uint256 animalId
    );

    event NewGiveway(
        address to,
        uint256 animalId,
        uint8 effectiveness
    );

    uint8 private constant AIRDROP_EFFECTIVENESS = 10;

    uint256 private pendingGivewayCardCount;
    uint256 private airdropEndTimestamp;

    bool private migrated = false;

    mapping (address => uint256[]) private addressDnaIds;
    mapping (address => bool) public addressIsDonator;
    mapping (uint => address) private dnaIdToOwnerAddress;

    Dna[] private dnas;

    constructor(
        uint256 _pendingGivewayCardCount,
        uint256 _airdropEndTimestamp
    ) public {
        pendingGivewayCardCount = _pendingGivewayCardCount;
        airdropEndTimestamp = _airdropEndTimestamp;
    }

    function getDna(uint dnaId) external view returns (
       uint256 animalId,
       address ownerAddress,
       uint8 effectiveness,
       uint256 id
    ) {
        Dna storage dna = dnas[dnaId];

        return (
            dna.animalId,
            dnaIdToOwnerAddress[dnaId],
            dna.effectiveness,
            dnaId
        );
    }

    function migrateData(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    external
    onlyOwner
    {
        require(migrated == false);
        donateDna(to, animalId, effectiveness);
    }

    function setMigrated() external onlyOwner {
        migrated = true;
    }

    function addDonator(address donatorAddress) external onlyAdmin {
        addressIsDonator[donatorAddress] = true;
    }

    function deleteDonator(address donatorAddress) external onlyAdmin {
        delete addressIsDonator[donatorAddress];
    }

    function airdrop(address to, uint256 animalId) external contractIsActive {
        require(now <= airdropEndTimestamp, "airdrop ended");
        donateDnaFromContract(to, animalId, AIRDROP_EFFECTIVENESS);
        emit NewAirdrop(to, animalId);
    }

    function giveaway(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    external
    contractIsActive
    {
        require(pendingGivewayCardCount > 0);

        donateDnaFromContract(to, animalId, effectiveness);
        pendingGivewayCardCount--;
        emit NewGiveway(to, animalId, effectiveness);
    }

    function getAddressDnaIds(address owner) external view returns(uint256[])
    {
        return addressDnaIds[owner];
    }

    function donateDnaFromContract(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    private
    contractIsActive
    {
        require(migrated);
        require(addressIsDonator[msg.sender], "donator not registered");
        donateDna(to, animalId, effectiveness);
    }

    function donateDna(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    private
    {
        uint256 id = dnas.length;  
        Dna memory dna = Dna(animalId, effectiveness);

         
        dnas.push(dna);
        dnaIdToOwnerAddress[id] = to;
        addressDnaIds[to].push(id);
    }
}