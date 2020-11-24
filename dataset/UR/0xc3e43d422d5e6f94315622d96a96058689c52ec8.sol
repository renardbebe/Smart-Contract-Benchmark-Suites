 

pragma solidity ^0.4.23;

 
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

 
contract Ownable {
    address internal owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        require(newOwner != address(0x0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

        return true;
    }
}

interface MintableToken {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferOwnership(address newOwner) external returns (bool);
}

interface BitNauticWhitelist {
    function AMLWhitelisted(address) external returns (bool);
}

interface BitNauticCrowdsale {
    function creditOf(address) external returns (uint256);
}

contract BitNauticCrowdsaleTokenDistributor is Ownable {
    using SafeMath for uint256;

    uint256 public constant ICOStartTime = 1531267200;  
    uint256 public constant ICOEndTime = 1536969600;  

    uint256 public teamSupply =     3000000 * 10 ** 18;  
    uint256 public bountySupply =   2500000 * 10 ** 18;  
    uint256 public reserveSupply =  5000000 * 10 ** 18;  
    uint256 public advisorSupply =  2500000 * 10 ** 18;  
    uint256 public founderSupply =  2000000 * 10 ** 18;  

    MintableToken public token;
    BitNauticWhitelist public whitelist;
    BitNauticCrowdsale public crowdsale;

    mapping (address => bool) public hasClaimedTokens;

    constructor(MintableToken _token, BitNauticWhitelist _whitelist, BitNauticCrowdsale _crowdsale) public {
        token = _token;
        whitelist = _whitelist;
        crowdsale = _crowdsale;
    }

    function privateSale(address beneficiary, uint256 tokenAmount) onlyOwner public {
        require(beneficiary != 0x0);

        assert(token.mint(beneficiary, tokenAmount));
    }

     
    function claimBitNauticTokens() public returns (bool) {
        return grantContributorTokens(msg.sender);
    }

     
    function grantContributorTokens(address contributor) public returns (bool) {
        require(!hasClaimedTokens[contributor]);
        require(crowdsale.creditOf(contributor) > 0);
        require(whitelist.AMLWhitelisted(contributor));
        require(now > ICOEndTime);

        assert(token.mint(contributor, crowdsale.creditOf(contributor)));
        hasClaimedTokens[contributor] = true;

        return true;
    }

    function transferTokenOwnership(address newTokenOwner) onlyOwner public returns (bool) {
        return token.transferOwnership(newTokenOwner);
    }

    function grantBountyTokens(address beneficiary) onlyOwner public {
        require(bountySupply > 0);

        token.mint(beneficiary, bountySupply);
        bountySupply = 0;
    }

    function grantReserveTokens(address beneficiary) onlyOwner public {
        require(reserveSupply > 0);

        token.mint(beneficiary, reserveSupply);
        reserveSupply = 0;
    }

    function grantAdvisorsTokens(address beneficiary) onlyOwner public {
        require(advisorSupply > 0);

        token.mint(beneficiary, advisorSupply);
        advisorSupply = 0;
    }

    function grantFoundersTokens(address beneficiary) onlyOwner public {
        require(founderSupply > 0);

        token.mint(beneficiary, founderSupply);
        founderSupply = 0;
    }

    function grantTeamTokens(address beneficiary) onlyOwner public {
        require(teamSupply > 0);

        token.mint(beneficiary, teamSupply);
        teamSupply = 0;
    }
}