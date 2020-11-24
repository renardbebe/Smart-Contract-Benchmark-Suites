 

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

 
 
contract ScheduleHold is Schedule {

    constructor(uint256 _tokenReleaseDate) Schedule(_tokenReleaseDate) public {
    }

     
     
    function vestedPercent() public view returns (uint256) {

        if(now < tokenReleaseDate || now < getReleaseTime(6)) {
            return 0;
            
        } else {
            return 100;
        }
    }
}