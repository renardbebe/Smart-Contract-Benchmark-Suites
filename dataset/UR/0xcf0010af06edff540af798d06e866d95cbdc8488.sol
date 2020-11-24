 

pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
     

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


     
    function registerInit(address _contract) external;

}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }


    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}

contract UnicornBreedingInterface {
    function deleteOffer(uint _unicornId) external;
    function deleteHybridization(uint _unicornId) external;
}


contract UnicornBase is UnicornAccessControl {
    using SafeMath for uint;
    UnicornBreedingInterface public unicornBreeding;  

    event Transfer(address indexed from, address indexed to, uint256 unicornId);
    event Approval(address indexed owner, address indexed approved, uint256 unicornId);
    event UnicornGeneSet(uint indexed unicornId);
    event UnicornGeneUpdate(uint indexed unicornId);
    event UnicornFreezingTimeSet(uint indexed unicornId, uint time);
    event UnicornTourFreezingTimeSet(uint indexed unicornId, uint time);


    struct Unicorn {
        bytes gene;
        uint64 birthTime;
        uint64 freezingEndTime;
        uint64 freezingTourEndTime;
        string name;
    }

    uint8 maxFreezingIndex = 7;
    uint32[8] internal freezing = [
    uint32(1 hours),     
    uint32(2 hours),     
    uint32(8 hours),     
    uint32(16 hours),    
    uint32(36 hours),    
    uint32(72 hours),    
    uint32(120 hours),   
    uint32(168 hours)    
    ];

     
    uint32[8] internal freezingPlusCount = [
    0, 3, 5, 9, 13, 25, 25, 0
    ];

     
    uint256 private totalUnicorns;

     
    uint256 private lastUnicornId;

     
    mapping(uint256 => Unicorn) public unicorns;

     
    mapping(uint256 => address) private unicornOwner;

     
    mapping(uint256 => address) private unicornApprovals;

     
    mapping(address => uint256[]) private ownedUnicorns;

     
     
    mapping(uint256 => uint256) private ownedUnicornsIndex;

     
    mapping(uint256 => bool) private unicornApprovalsForGeneLab;

    modifier onlyOwnerOf(uint256 _unicornId) {
        require(owns(msg.sender, _unicornId));
        _;
    }

     
    function ownerOf(uint256 _unicornId) public view returns (address) {
        return unicornOwner[_unicornId];
         
         
         
    }

    function totalSupply() public view returns (uint256) {
        return totalUnicorns;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedUnicorns[_owner].length;
    }

     
    function unicornsOf(address _owner) public view returns (uint256[]) {
        return ownedUnicorns[_owner];
    }

     
    function approvedFor(uint256 _unicornId) public view returns (address) {
        return unicornApprovals[_unicornId];
    }

     
    function allowance(address _owner, uint256 _unicornId) public view returns (bool) {
        return approvedFor(_unicornId) == _owner;
    }

     
    function approve(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
         
         
        require(_to != msg.sender);
        if (approvedFor(_unicornId) != address(0) || _to != address(0)) {
            unicornApprovals[_unicornId] = _to;
            emit Approval(msg.sender, _to, _unicornId);
        }
    }

     
    function takeOwnership(uint256 _unicornId) public {
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(ownerOf(_unicornId), msg.sender, _unicornId);
    }

     
    function transfer(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        clearApprovalAndTransfer(msg.sender, _to, _unicornId);
    }


     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _unicornId) internal {
        require(owns(_from, _unicornId));
        require(_to != address(0));
        require(_to != ownerOf(_unicornId));

        clearApproval(_from, _unicornId);
        removeUnicorn(_from, _unicornId);
        addUnicorn(_to, _unicornId);
        emit Transfer(_from, _to, _unicornId);
    }

     
    function clearApproval(address _owner, uint256 _unicornId) private {
        require(owns(_owner, _unicornId));
        unicornApprovals[_unicornId] = 0;
        emit Approval(_owner, 0, _unicornId);
    }

     
    function addUnicorn(address _to, uint256 _unicornId) private {
        require(unicornOwner[_unicornId] == address(0));
        unicornOwner[_unicornId] = _to;
         
        uint256 length = ownedUnicorns[_to].length;
        ownedUnicorns[_to].push(_unicornId);
        ownedUnicornsIndex[_unicornId] = length;
        totalUnicorns = totalUnicorns.add(1);
    }

     
    function removeUnicorn(address _from, uint256 _unicornId) private {
        require(owns(_from, _unicornId));

        uint256 unicornIndex = ownedUnicornsIndex[_unicornId];
         
        uint256 lastUnicornIndex = ownedUnicorns[_from].length.sub(1);
        uint256 lastUnicorn = ownedUnicorns[_from][lastUnicornIndex];

        unicornOwner[_unicornId] = 0;
        ownedUnicorns[_from][unicornIndex] = lastUnicorn;
        ownedUnicorns[_from][lastUnicornIndex] = 0;
         
         
         

        ownedUnicorns[_from].length--;
        ownedUnicornsIndex[_unicornId] = 0;
        ownedUnicornsIndex[lastUnicorn] = unicornIndex;
        totalUnicorns = totalUnicorns.sub(1);

         
         
         
        unicornBreeding.deleteOffer(_unicornId);
        unicornBreeding.deleteHybridization(_unicornId);
         
    }

     
     
     
     
     
     
     
     
     
     


    function createUnicorn(address _owner) onlyBreeding external returns (uint) {
        require(_owner != address(0));
        uint256 _unicornId = lastUnicornId++;
        addUnicorn(_owner, _unicornId);
         
        unicorns[_unicornId] = Unicorn({
            gene : new bytes(0),
            birthTime : uint64(now),
            freezingEndTime : 0,
            freezingTourEndTime: 0,
            name: ''
            });
        emit Transfer(0x0, _owner, _unicornId);
        return _unicornId;
    }


    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return ownerOf(_unicornId) == _claimant && ownerOf(_unicornId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public {
        require(_to != address(this));
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }


    function fromHexChar(uint8 _c) internal pure returns (uint8) {
        return _c - (_c < 58 ? 48 : (_c < 97 ? 55 : 87));
    }


    function getUnicornGenByte(uint _unicornId, uint _byteNo) public view returns (uint8) {
        uint n = _byteNo << 1;  
         
        if (unicorns[_unicornId].gene.length < n + 1) {
            return 0;
        }
        return fromHexChar(uint8(unicorns[_unicornId].gene[n])) << 4 | fromHexChar(uint8(unicorns[_unicornId].gene[n + 1]));
    }


    function setName(uint256 _unicornId, string _name ) public onlyOwnerOf(_unicornId) returns (bool) {
        bytes memory tmp = bytes(unicorns[_unicornId].name);
        require(tmp.length == 0);

        unicorns[_unicornId].name = _name;
        return true;
    }


    function getGen(uint _unicornId) external view returns (bytes){
        return unicorns[_unicornId].gene;
    }

    function setGene(uint _unicornId, bytes _gene) onlyBlackBox external  {
        if (unicorns[_unicornId].gene.length == 0) {
            unicorns[_unicornId].gene = _gene;
            emit UnicornGeneSet(_unicornId);
        }
    }

    function updateGene(uint _unicornId, bytes _gene) onlyGeneLab public {
        require(unicornApprovalsForGeneLab[_unicornId]);
        delete unicornApprovalsForGeneLab[_unicornId];
        unicorns[_unicornId].gene = _gene;
        emit UnicornGeneUpdate(_unicornId);
    }

    function approveForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        unicornApprovalsForGeneLab[_unicornId] = true;
    }

    function clearApprovalForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        delete unicornApprovalsForGeneLab[_unicornId];
    }

     
    function marketTransfer(address _from, address _to, uint256 _unicornId) onlyBreeding external {
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }

    function plusFreezingTime(uint _unicornId) onlyBreeding external  {
        unicorns[_unicornId].freezingEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 163)) + now);
        emit UnicornFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingEndTime);
    }

    function plusTourFreezingTime(uint _unicornId) onlyBreeding external {
        unicorns[_unicornId].freezingTourEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 168)) + now);
        emit UnicornTourFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingTourEndTime);
    }

    function _getFreezeTime(uint8 freezingIndex) internal view returns (uint time) {
        freezingIndex %= maxFreezingIndex;
        time = freezing[freezingIndex];
        if (freezingPlusCount[freezingIndex] != 0) {
            time += (uint(block.blockhash(block.number - 1)) % freezingPlusCount[freezingIndex]) * 1 hours;
        }
    }


     
    function minusFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
         
        require(unicorns[_unicornId].freezingEndTime > now);
         
        unicorns[_unicornId].freezingEndTime -= _time;
    }

     
    function minusTourFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
         
        require(unicorns[_unicornId].freezingTourEndTime > now);
         
        unicorns[_unicornId].freezingTourEndTime -= _time;
    }

    function isUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingEndTime <= uint64(now));
    }

    function isTourUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingTourEndTime <= uint64(now));
    }

}

contract UnicornToken is UnicornBase {
    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

    function UnicornToken(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {

    }

    function init() onlyManagement whenPaused external {
        unicornBreeding = UnicornBreedingInterface(unicornManagement.unicornBreedingAddress());
    }

    function() public {

    }
}