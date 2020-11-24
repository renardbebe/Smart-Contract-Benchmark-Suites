 

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

     
     
     
     
     

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract LandTokenInterface {
     
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _landId) public view returns (address _owner);
    function transfer(address _to, uint256 _landId) public;
    function approve(address _to, uint256 _landId) public;
    function takeOwnership(uint256 _landId) public;
    function totalSupply() public view returns (uint);
    function owns(address _claimant, uint256 _landId) public view returns (bool);
    function allowance(address _claimant, uint256 _landId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _landId) public;
    function createLand(address _owner) external returns (uint);
}

interface tokenRecipient {
    function receiveApproval(address _from, address _token, uint _value, bytes _extraData) external;
    function receiveCreateAuction(address _from, address _token, uint _landId, uint _startPrice, uint _duration) external;
    function receiveCreateAuctionFromArray(address _from, address _token, uint[] _landIds, uint _startPrice, uint _duration) external;
}

contract LandBase is Ownable {
    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint256 landId);
    event Approval(address indexed owner, address indexed approved, uint256 landId);
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


    modifier onlyOwnerOf(uint256 _landId) {
        require(owns(msg.sender, _landId));
        _;
    }

     
    function ownerOf(uint256 _landId) public view returns (address) {
        return landOwner[_landId];
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

     
    function approvedFor(uint256 _landId) public view returns (address) {
        return landApprovals[_landId];
    }

     
    function allowance(address _owner, uint256 _landId) public view returns (bool) {
        return approvedFor(_landId) == _owner;
    }

     
    function approve(address _to, uint256 _landId) public onlyOwnerOf(_landId) returns (bool) {
        require(_to != msg.sender);
        if (approvedFor(_landId) != address(0) || _to != address(0)) {
            landApprovals[_landId] = _to;
            emit Approval(msg.sender, _to, _landId);
            return true;
        }
    }


    function approveAndCall(address _spender, uint256 _landId, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _landId)) {
            spender.receiveApproval(msg.sender, this, _landId, _extraData);
            return true;
        }
    }


    function createAuction(address _auction, uint _landId, uint _startPrice, uint _duration) public returns (bool) {
        tokenRecipient auction = tokenRecipient(_auction);
        if (approve(_auction, _landId)) {
            auction.receiveCreateAuction(msg.sender, this, _landId, _startPrice, _duration);
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

     
    function takeOwnership(uint256 _landId) public {
        require(allowance(msg.sender, _landId));
        clearApprovalAndTransfer(ownerOf(_landId), msg.sender, _landId);
    }

     
    function transfer(address _to, uint256 _landId) public onlyOwnerOf(_landId) returns (bool) {
        clearApprovalAndTransfer(msg.sender, _to, _landId);
        return true;
    }


     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _landId) internal {
        require(owns(_from, _landId));
        require(_to != address(0));
        require(_to != ownerOf(_landId));

        clearApproval(_from, _landId);
        removeLand(_from, _landId);
        addLand(_to, _landId);
        emit Transfer(_from, _to, _landId);
    }

     
    function clearApproval(address _owner, uint256 _landId) private {
        require(owns(_owner, _landId));
        landApprovals[_landId] = address(0);
        emit Approval(_owner, address(0), _landId);
    }

     
    function addLand(address _to, uint256 _landId) private {
        require(landOwner[_landId] == address(0));
        landOwner[_landId] = _to;

        uint256 length = ownedLands[_to].length;
        ownedLands[_to].push(_landId);
        ownedLandsIndex[_landId] = length;
        totalLands = totalLands.add(1);
    }

     
    function removeLand(address _from, uint256 _landId) private {
        require(owns(_from, _landId));

        uint256 landIndex = ownedLandsIndex[_landId];
         
        uint256 lastLandIndex = ownedLands[_from].length.sub(1);
        uint256 lastLand = ownedLands[_from][lastLandIndex];

        landOwner[_landId] = address(0);
        ownedLands[_from][landIndex] = lastLand;
        ownedLands[_from][lastLandIndex] = 0;
         
         
         

        ownedLands[_from].length--;
        ownedLandsIndex[_landId] = 0;
        ownedLandsIndex[lastLand] = landIndex;
        totalLands = totalLands.sub(1);
    }


    function createLand(address _owner, uint _id) onlyOwner public returns (uint) {
        require(_owner != address(0));
        uint256 _landId = lastLandId++;
        addLand(_owner, _landId);
         
        lands[_landId] = Land({
            id : _id
            });
        emit Transfer(address(0), _owner, _landId);
        emit NewLand(_owner, _landId);
        return _landId;
    }

    function createLandAndAuction(address _owner, uint _id, address _auction, uint _startPrice, uint _duration) onlyOwner public
    {
        uint id = createLand(_owner, _id);
        require(createAuction(_auction, id, _startPrice, _duration));
    }


    function owns(address _claimant, uint256 _landId) public view returns (bool) {
        return ownerOf(_landId) == _claimant && ownerOf(_landId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _landId) public returns (bool) {
        require(_to != address(this));
        require(allowance(msg.sender, _landId));
        clearApprovalAndTransfer(_from, _to, _landId);
        return true;
    }

}


contract ArconaDigitalLand is LandBase {
    string public constant name = " Arcona Digital Land";
    string public constant symbol = "ARDL";

    function() public payable{
        revert();
    }
}