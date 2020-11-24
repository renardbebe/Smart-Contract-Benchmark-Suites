 

contract MarriageRegistry {
    address [] public registeredMarriages;
    event ContractCreated(address contractAddress);

    function createMarriage(string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
        address newMarriage = new Marriage(msg.sender, _leftName, _leftVows, _rightName, _rightVows, _date);
        emit ContractCreated(newMarriage);
        registeredMarriages.push(newMarriage);
    }

    function getDeployedMarriages() public view returns (address[]) {
        return registeredMarriages;
    }
}

 
contract Marriage {

    event weddingBells(address ringer, uint256 count);

     
    address public owner;

     
    string public leftName;
    string public leftVows;
    string public rightName;
    string public rightVows;
     
    uint public marriageDate;
    
     
    uint256 public bellCounter;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    constructor(address _owner, string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
         
        owner = _owner;
        leftName = _leftName;
        leftVows = _leftVows;
        rightName = _rightName;
        rightVows = _rightVows;
        marriageDate = _date; 
    }

     
    function add(uint256 a, uint256 b) private pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function ringBell() public payable {
        bellCounter = add(1, bellCounter);
        emit weddingBells(msg.sender, bellCounter);
    }

     
    function collect() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

     
    function getMarriageDetails() public view returns (
        address, string, string, string, string, uint, uint256) {
        return (
            owner,
            leftName,
            leftVows,
            rightName,
            rightVows,
            marriageDate,
            bellCounter
        );
    }
}