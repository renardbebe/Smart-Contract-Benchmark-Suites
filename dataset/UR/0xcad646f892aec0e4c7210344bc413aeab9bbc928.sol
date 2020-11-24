 

pragma solidity ^0.4.24;

 
 
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

contract YumeriumManager {
    function getYumerium(uint256 value, address sender) external returns (uint256);
}

contract Sale {
    uint public saleEnd1 = 1535846400 + 1 days;  
    uint public saleEnd2 = saleEnd1 + 1 days;  
    uint public saleEnd3 = saleEnd2 + 1 days;  
    uint public saleEnd4 = 1539129600;  
    uint256 public minEthValue = 10 ** 15;  

    uint256 public totalPariticpants = 0;
    uint256 public adjustedValue = 0;
    mapping(address => Renowned) public renownedPlayers;  
    mapping(bytes8 => address) public referral;  
    
    using SafeMath for uint256;
    uint256 public maxSale;
    uint256 public totalSaled;
    
    YumeriumManager public manager;
    address public owner;

    event Contribution(address from, uint256 amount);

    constructor(address _manager_address) public {
        maxSale = 316906850 * 10 ** 8; 
        manager = YumeriumManager(_manager_address);
        owner = msg.sender;
    }

    function () external payable {
        buy("");
    }

     
     
    function contribute(bytes8 referralCode) external payable {
        buy(referralCode);
    }
    
    function becomeRenown() public payable {
        generateRenown();
        owner.transfer(msg.value);
    }

    function generateRenown() private {
        require(!renownedPlayers[msg.sender].isRenowned, "You already registered as renowned!");
        bytes8 referralCode = bytes8(keccak256(abi.encodePacked(totalPariticpants + adjustedValue)));
         
        while (renownedPlayers[referral[referralCode]].isRenowned)
        {
            adjustedValue = adjustedValue.add(1);
            referralCode = bytes8(keccak256(abi.encodePacked(totalPariticpants + adjustedValue)));
        }
        renownedPlayers[msg.sender].addr = msg.sender;
        renownedPlayers[msg.sender].referralCode = referralCode;
        renownedPlayers[msg.sender].isRenowned = true;
        referral[renownedPlayers[msg.sender].referralCode] = msg.sender;
        totalPariticpants = totalPariticpants.add(1);
    }
    
    function buy(bytes8 referralCode) internal {
        require(msg.value>=minEthValue);
        require(now < saleEnd4);  

         
        uint256 remainEth = msg.value;
        if (referral[referralCode] != msg.sender && renownedPlayers[referral[referralCode]].isRenowned)
        {
            uint256 referEth = msg.value.mul(10).div(100);
            referral[referralCode].transfer(referEth);
            remainEth = remainEth.sub(referEth);
        }

        if (!renownedPlayers[msg.sender].isRenowned)
        {
            generateRenown();
        }
        
        uint256 amount = manager.getYumerium(msg.value, msg.sender);
        uint256 total = totalSaled.add(amount);
        owner.transfer(remainEth);
        
        require(total<=maxSale);
        
        totalSaled = total;
        
        emit Contribution(msg.sender, amount);
    }

     
    function changeManagerAddress(address _manager_address) external {
        require(msg.sender==owner, "You are not an owner!");
        manager = YumeriumManager(_manager_address);
    }
     
    function changeTeamWallet(address _team_address) external {
        require(msg.sender==owner, "You are not an owner!");
        owner = YumeriumManager(_team_address);
    }

    struct Renowned {
        bool isRenowned;
        address addr;
        bytes8 referralCode;
    }
}