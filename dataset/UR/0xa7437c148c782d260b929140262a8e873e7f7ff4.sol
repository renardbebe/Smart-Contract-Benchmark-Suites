 

pragma solidity 0.5.9;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
contract Bussiness is Ownable {
    uint public periodToPlay = 60;  

    mapping(address => uint) public timeTrackUser;
    event _random(address _from, uint _ticket);
    constructor() public {}
    function getAward() public {
        require(isValidToPlay());
        timeTrackUser[msg.sender] = block.timestamp;
        emit _random(msg.sender, block.timestamp);
    }

    function isValidToPlay() public view returns (bool){
        return periodToPlay <= now - timeTrackUser[msg.sender];
    }
    function changePeriodToPlay(uint _period) onlyOwner public{
        periodToPlay = _period;
    }

}