 

 

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

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

    
 
contract VSUpayments {

    using SafeMath for uint256;

    Token public militaryToken;
    address public owner;
    uint public lockUpEnd;
    uint public awardsEnd;
    mapping (address => uint256) public award;
    mapping (address => uint256) public withdrawn;
    uint256 public totalAwards = 0;
    uint256 public currentAwards = 0;

     
    constructor(address _militaryToken) public {
        militaryToken = Token(_militaryToken);
        owner = msg.sender;
        lockUpEnd = now + (365 days);
        awardsEnd = now + (730 days);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier preEnd() {
        require(now < lockUpEnd);
        _;
    }

     
    modifier postEnd() {
        require(lockUpEnd <= now);
        _;
    }

     
    modifier funded() {
        require(currentAwards <= militaryToken.balanceOf(address(this)));
        _;
    }

    modifier awardsAllowed() {
        require(now < awardsEnd);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if(newOwner != address(0)) {
            owner = newOwner;
        }
    }

     
    function awardMILsTo(address _to, uint256 _MILs) public onlyOwner awardsAllowed {
        
        award[_to] = award[_to].add(_MILs);
        totalAwards = totalAwards.add(_MILs);
        currentAwards = currentAwards.add(_MILs);
    }

     
    function withdrawMILs(uint256 _MILs) public postEnd funded {
        uint256 daysSinceEnd = (now - lockUpEnd) / 1 days;
        uint256 maxPct = min(((daysSinceEnd / 30 + 1) * 25), 100);
        uint256 allowed = award[msg.sender];
        allowed = allowed * maxPct / 100;
        allowed -= withdrawn[msg.sender];
        require(_MILs <= allowed);
        militaryToken.transfer(msg.sender, _MILs);
        withdrawn[msg.sender] += _MILs;
        currentAwards -= _MILs;
    }

     
    function recoverUnawardedMILs() public  {
        uint256 MILs = militaryToken.balanceOf(address(this));
        if(totalAwards < MILs) {
            militaryToken.transfer(owner, MILs - totalAwards);
        }
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}