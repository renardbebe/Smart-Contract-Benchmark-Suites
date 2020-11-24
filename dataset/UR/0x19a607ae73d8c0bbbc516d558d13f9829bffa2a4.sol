 

pragma solidity 0.4.24;


 
 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
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

 
 
contract Schedule is Ownable {
    using SafeMath for uint256;

     
    uint256 public tokenReleaseDate;

     
    uint256 public releaseInterval = 30 days;

    constructor(uint256 _tokenReleaseDate) public {
        tokenReleaseDate = _tokenReleaseDate;
    }

     
     
    function setTokenReleaseDate(uint256 newReleaseDate) public onlyOwner {
        tokenReleaseDate = newReleaseDate;
    }

     
     
    function vestedPercent() public view returns (uint256);

     
     
     
    function getReleaseTime(uint256 intervals) public view returns (uint256) {
        return tokenReleaseDate.add(releaseInterval.mul(intervals));
    }
}

 
 
 
 
 
 
 
 
contract ScheduleStandard is Schedule {

    constructor(uint256 _tokenReleaseDate) Schedule(_tokenReleaseDate) public {
    }

     
     
    function vestedPercent() public view returns (uint256) {
        uint256 percentReleased = 0;

        if(now < tokenReleaseDate) {
            percentReleased = 0;
            
        } else if(now >= getReleaseTime(5)) {
            percentReleased = 100;

        } else if(now >= getReleaseTime(4)) {
            percentReleased = 85;

        } else if(now >= getReleaseTime(3)) {
            percentReleased = 70;

        } else if(now >= getReleaseTime(2)) {
            percentReleased = 55;

        } else if(now >= getReleaseTime(1)) {
            percentReleased = 30;

        } else {
            percentReleased = 15;
        }
        return percentReleased;
    }
}