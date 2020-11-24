 

pragma solidity 0.5.10;

 
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
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}
contract Bussiness is Ownable {
    uint public periodToPlay = 900;  
    uint256 public requireBST = 1000;  
    bool public isEnded;
    address Boost = 0xfADa6A9BC9A5C7cA147ee6A7CdC428938dEB7662;
    ERC20BasicInterface public boostToken = ERC20BasicInterface(Boost);
    mapping(address => uint) public timeTrackUser;
    event _random(address _from, uint _ticket);
    constructor() public {}
    function getAward() public {
        require(isValidToPlay());
        timeTrackUser[msg.sender] = block.timestamp;
        emit _random(msg.sender, block.timestamp);
    }

    function isValidToPlay() public view returns (bool){
        return (!isEnded
        && periodToPlay <= now - timeTrackUser[msg.sender]
        && boostToken.balanceOf(msg.sender) >= requireBST);
    }
    function changePeriodToPlay(uint _period) onlyOwner public{
        periodToPlay = _period;
    }
    function updateGetAward() onlyOwner public{
        isEnded = true;
    }
    function updateRequireBST(uint256 _requireBST) onlyOwner public{
        requireBST = _requireBST;
    }

}