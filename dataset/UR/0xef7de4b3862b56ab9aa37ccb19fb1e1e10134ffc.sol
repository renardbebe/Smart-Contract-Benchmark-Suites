 

pragma solidity ^0.4.17;

 
 
 
contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

     
     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }

        _;
    }

    modifier onlyOwnerCandidate() {
        if (msg.sender != newOwnerCandidate) {
            revert();
        }

        _;
    }

     
     
    function requestOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() external onlyOwnerCandidate {
        address previousOwner = owner;

        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);

        OwnershipTransferred(previousOwner, owner);
    }
}

 
 
contract EtherDick is Ownable {

    event NewBiggestDick(string name, string notes, uint256 size);

    struct BiggestDick {
        string name;
        string notes;
        uint256 size;
        uint256 timestamp;
        address who;
    }

    BiggestDick[] private biggestDicks;

    function EtherDick() public {
        biggestDicks.push(BiggestDick({
            name:       'Brian',
            notes:      'First dick',
            size:      9,
            timestamp:  block.timestamp,
            who:        address(0)
            }));
    }

     
    function iHaveABiggerDick(string name, string notes) external payable {

        uint nameLen = bytes(name).length;
        uint notesLen = bytes(notes).length;

        require(msg.sender != address(0));
        require(nameLen > 2);
        require(nameLen <= 64);
        require(notesLen <= 140);
        require(msg.value > biggestDicks[biggestDicks.length - 1].size);

        BiggestDick memory bd = BiggestDick({
            name:       name,
            notes:      notes,
            size:       msg.value,
            timestamp:  block.timestamp,
            who:        msg.sender
        });

        biggestDicks.push(bd);

        NewBiggestDick(name, notes, msg.value);
    }

     
    function howManyDicks() external view
            returns (uint) {

        return biggestDicks.length;
    }

     
    function whoHasTheBiggestDick() external view
            returns (string name, string notes, uint256 size, uint256 timestamp, address who) {

        BiggestDick storage bd = biggestDicks[biggestDicks.length - 1];
        return (bd.name, bd.notes, bd.size, bd.timestamp, bd.who);
    }

     
    function whoHadTheBiggestDick(uint position) external view
            returns (string name, string notes, uint256 size, uint256 timestamp, address who) {

        BiggestDick storage bd = biggestDicks[position];
        return (bd.name, bd.notes, bd.size, bd.timestamp, bd.who);
    }

     
    function transferBalance(address to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

}