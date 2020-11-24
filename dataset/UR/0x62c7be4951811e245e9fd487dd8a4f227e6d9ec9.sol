 

 

pragma solidity ^0.5.0;

 
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}


 
interface HouseContract {
     function owner() external view returns (address); 
     function isHouse() external view returns (bool);
     function isPlayer(address playerAddress) external view returns(bool);
}

 
contract Tracker is SafeMath, Owned {




    enum Action { added, updated}

    struct House {            
        uint upVotes;             
        uint downVotes;
        bool isActive;
        address oldAddress;
        address owner;
    }

    struct TrackerData { 
        string  name;
        string  creatorName;
        bool  managed;
        uint trackerVersion;
    }    


    TrackerData public trackerData;

     
    mapping (address => House) public houses;

     
    mapping (address => mapping (address => bool)) public playerUpvoted;

     
    mapping (address => mapping (address => bool)) public playerDownvoted;

     
    event TrackerChanged(address indexed  newHouseAddress, Action action);

     
    event TrackerCreated();

     
    event TrackerNamesUpdated();    


     
    constructor(string memory trackerName, string memory trackerCreatorName, bool trackerIsManaged, uint version) public {
        trackerData.name = trackerName;
        trackerData.creatorName = trackerCreatorName;
        trackerData.managed = trackerIsManaged;
        trackerData.trackerVersion = version;
        emit TrackerCreated();
    }

      
    function updateTrackerNames(string memory newName, string memory newCreatorName) onlyOwner public {
        trackerData.name = newName;
        trackerData.creatorName = newCreatorName;
        emit TrackerNamesUpdated();
    }    

      
    function addHouse(address houseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(!houses[houseAddress].isActive,"There is a new version of House already registered");    
        HouseContract houseContract = HouseContract(houseAddress);
        require(houseContract.isHouse(),"Invalid House");
        houses[houseAddress].isActive = true;
        houses[houseAddress].owner = houseContract.owner();
        emit TrackerChanged(houseAddress,Action.added);
    }

     
    function updateHouse(address newHouseAddress,address oldHouseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(houses[oldHouseAddress].owner==msg.sender || houses[oldHouseAddress].owner==oldHouseAddress,"Caller isn't the owner of old House");
        require(!houses[newHouseAddress].isActive,"There is a new version of House already registered");  
        HouseContract houseContract = HouseContract(newHouseAddress);
        require(houseContract.isHouse(),"Invalid House");
        houses[oldHouseAddress].isActive = false;
        houses[newHouseAddress].isActive = true;
        houses[newHouseAddress].owner = houseContract.owner();
        houses[newHouseAddress].upVotes = houses[oldHouseAddress].upVotes;
        houses[newHouseAddress].downVotes = houses[oldHouseAddress].downVotes;
        houses[newHouseAddress].oldAddress = oldHouseAddress;
        emit TrackerChanged(newHouseAddress,Action.added);
        emit TrackerChanged(oldHouseAddress,Action.updated);
    }

      
    function removeHouse(address houseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(houses[houseAddress].owner==msg.sender,"Caller isn't the owner of House");  
        houses[houseAddress].isActive = false;
        emit TrackerChanged(houseAddress,Action.updated);
    }

      
    function upVoteHouse(address houseAddress) public {
        require(HouseContract(houseAddress).isPlayer(msg.sender),"Caller hasn't placed any bet");
        require(!playerUpvoted[msg.sender][houseAddress],"Has already Upvoted");
        playerUpvoted[msg.sender][houseAddress] = true;
        houses[houseAddress].upVotes += 1;
        emit TrackerChanged(houseAddress,Action.updated);
    }

      
    function downVoteHouse(address houseAddress) public {
        require(HouseContract(houseAddress).isPlayer(msg.sender),"Caller hasn't placed any bet");
        require(!playerDownvoted[msg.sender][houseAddress],"Has already Downvoted");
        playerDownvoted[msg.sender][houseAddress] = true;
        houses[houseAddress].downVotes += 1;
        emit TrackerChanged(houseAddress,Action.updated);
    }    

     
    function kill() onlyOwner public {
        selfdestruct(owner); 
    }

}