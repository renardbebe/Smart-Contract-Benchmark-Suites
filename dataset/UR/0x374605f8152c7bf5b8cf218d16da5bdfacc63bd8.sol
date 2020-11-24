 

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract EthNote is Ownable {

    mapping (address => string) notes;

    event Note(address indexed owner, string value);


    function setNote(string memory note) public {
        notes[msg.sender] = note;

        emit Note(msg.sender, note);
    }

    function setNoteOwner(address noteOwner, string memory note) public onlyOwner {
        notes[noteOwner] = note;

        emit Note(noteOwner, note);
    }

    function getNote(address noteOwner) public view returns (string memory) {
        return notes[noteOwner];
    }

}