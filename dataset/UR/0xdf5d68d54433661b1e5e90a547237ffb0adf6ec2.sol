 

pragma solidity 0.4.24;

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

contract Ownable {
    address public owner;
    mapping(address => bool) admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed admin);
    event DelAdmin(address indexed admin);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    function addAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0));
        admins[_adminAddress] = true;
        emit AddAdmin(_adminAddress);
    }

    function delAdmin(address _adminAddress) external onlyOwner {
        require(admins[_adminAddress]);
        admins[_adminAddress] = false;
        emit DelAdmin(_adminAddress);
    }

    function isAdmin(address _adminAddress) public view returns (bool) {
        return admins[_adminAddress];
    }
     
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}



interface tokenRecipient {
    function receiveApproval(address _from, address _token, uint _value, bytes _extraData) external;
    function receiveCreateAuction(address _from, address _token, uint _tokenId, uint _startPrice, uint _duration) external;
    function receiveCreateAuctionFromArray(address _from, address _token, uint[] _landIds, uint _startPrice, uint _duration) external;
}


contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool);
    function transfer(address _to, uint256 _tokenId) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}



contract LandBase is ERC721, Ownable {
    using SafeMath for uint;

    event NewLand(address indexed owner, uint256 landId);

    struct Land {
        uint id;
    }


     
    uint256 private totalLands;

     
    uint256 private lastLandId;

     
    mapping(uint256 => Land) public lands;

     
    mapping(uint256 => address) private landOwner;

     
    mapping(uint256 => address) private landApprovals;

     
    mapping(address => uint256[]) private ownedLands;

     
     
    mapping(uint256 => uint256) private ownedLandsIndex;


    modifier onlyOwnerOf(uint256 _tokenId) {
        require(owns(msg.sender, _tokenId));
        _;
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return landOwner[_tokenId];
    }

    function totalSupply() public view returns (uint256) {
        return totalLands;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedLands[_owner].length;
    }

     
    function landsOf(address _owner) public view returns (uint256[]) {
        return ownedLands[_owner];
    }

     
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return landApprovals[_tokenId];
    }

     
    function allowance(address _owner, uint256 _tokenId) public view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }

     
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool) {
        require(_to != msg.sender);
        if (approvedFor(_tokenId) != address(0) || _to != address(0)) {
            landApprovals[_tokenId] = _to;
            emit Approval(msg.sender, _to, _tokenId);
            return true;
        }
    }


    function approveAndCall(address _spender, uint256 _tokenId, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _tokenId)) {
            spender.receiveApproval(msg.sender, this, _tokenId, _extraData);
            return true;
        }
    }


    function createAuction(address _auction, uint _tokenId, uint _startPrice, uint _duration) public returns (bool) {
        tokenRecipient auction = tokenRecipient(_auction);
        if (approve(_auction, _tokenId)) {
            auction.receiveCreateAuction(msg.sender, this, _tokenId, _startPrice, _duration);
            return true;
        }
    }


    function createAuctionFromArray(address _auction, uint[] _landIds, uint _startPrice, uint _duration) public returns (bool) {
        tokenRecipient auction = tokenRecipient(_auction);

        for (uint i = 0; i < _landIds.length; ++i)
            require(approve(_auction, _landIds[i]));

        auction.receiveCreateAuctionFromArray(msg.sender, this, _landIds, _startPrice, _duration);
        return true;
    }

     
    function takeOwnership(uint256 _tokenId) public {
        require(allowance(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
        return true;
    }


    function ownerTransfer(address _from, address _to, uint256 _tokenId) onlyAdmin public returns (bool) {
        clearApprovalAndTransfer(_from, _to, _tokenId);
        return true;
    }

     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(owns(_from, _tokenId));
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));

        clearApproval(_from, _tokenId);
        removeLand(_from, _tokenId);
        addLand(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(owns(_owner, _tokenId));
        landApprovals[_tokenId] = address(0);
        emit Approval(_owner, address(0), _tokenId);
    }

     
    function addLand(address _to, uint256 _tokenId) private {
        require(landOwner[_tokenId] == address(0));
        landOwner[_tokenId] = _to;

        uint256 length = ownedLands[_to].length;
        ownedLands[_to].push(_tokenId);
        ownedLandsIndex[_tokenId] = length;
        totalLands = totalLands.add(1);
    }

     
    function removeLand(address _from, uint256 _tokenId) private {
        require(owns(_from, _tokenId));

        uint256 landIndex = ownedLandsIndex[_tokenId];
         
        uint256 lastLandIndex = ownedLands[_from].length.sub(1);
        uint256 lastLand = ownedLands[_from][lastLandIndex];

        landOwner[_tokenId] = address(0);
        ownedLands[_from][landIndex] = lastLand;
        ownedLands[_from][lastLandIndex] = 0;
         
         
         

        ownedLands[_from].length--;
        ownedLandsIndex[_tokenId] = 0;
        ownedLandsIndex[lastLand] = landIndex;
        totalLands = totalLands.sub(1);
    }


    function createLand(address _owner, uint _id) onlyAdmin public returns (uint) {
        require(_owner != address(0));
        uint256 _tokenId = lastLandId++;
        addLand(_owner, _tokenId);
         
        lands[_tokenId] = Land({
            id : _id
            });
        emit Transfer(address(0), _owner, _tokenId);
        emit NewLand(_owner, _tokenId);
        return _tokenId;
    }

    function createLandAndAuction(address _owner, uint _id, address _auction, uint _startPrice, uint _duration) onlyAdmin public
    {
        uint id = createLand(_owner, _id);
        require(createAuction(_auction, id, _startPrice, _duration));
    }


    function owns(address _claimant, uint256 _tokenId) public view returns (bool) {
        return ownerOf(_tokenId) == _claimant && ownerOf(_tokenId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) {
        require(_to != address(this));
        require(allowance(msg.sender, _tokenId));
        clearApprovalAndTransfer(_from, _to, _tokenId);
        return true;
    }

}


contract ArconaDigitalLand is LandBase {
    string public constant name = " Arcona Digital Land";
    string public constant symbol = "ARDL";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    function() public payable{
        revert();
    }
}