 

 

 
 
contract Token {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract SingularDTVToken is Token {
    function issueTokens(address _for, uint tokenCount) returns (bool);
}
contract SingularDTVCrowdfunding {
    function twoYearsPassed() returns (bool);
    function startDate() returns (uint);
    function CROWDFUNDING_PERIOD() returns (uint);
    function TOKEN_TARGET() returns (uint);
    function valuePerShare() returns (uint);
    function fundBalance() returns (uint);
    function campaignEndedSuccessfully() returns (bool);
}


 
 
contract SingularDTVFund {

     
    SingularDTVToken public singularDTVToken;
    SingularDTVCrowdfunding public singularDTVCrowdfunding;

     
    address public owner;
    address constant public workshop = 0xc78310231aA53bD3D0FEA2F8c705C67730929D8f;
    uint public totalRevenue;

     
    mapping (address => uint) public revenueAtTimeOfWithdraw;

     
    mapping (address => uint) public owed;

     
    modifier noEther() {
        if (msg.value > 0) {
            throw;
        }
        _
    }

    modifier onlyOwner() {
         
        if (msg.sender != owner) {
            throw;
        }
        _
    }

    modifier campaignEndedSuccessfully() {
        if (!singularDTVCrowdfunding.campaignEndedSuccessfully()) {
            throw;
        }
        _
    }

     
     
    function depositRevenue()
        external
        campaignEndedSuccessfully
        returns (bool)
    {
        totalRevenue += msg.value;
        return true;
    }

     
     
    function calcRevenue(address forAddress) internal returns (uint) {
        return singularDTVToken.balanceOf(forAddress) * (totalRevenue - revenueAtTimeOfWithdraw[forAddress]) / singularDTVToken.totalSupply();
    }

     
    function withdrawRevenue()
        external
        noEther
        returns (uint)
    {
        uint value = calcRevenue(msg.sender) + owed[msg.sender];
        revenueAtTimeOfWithdraw[msg.sender] = totalRevenue;
        owed[msg.sender] = 0;
        if (value > 0 && !msg.sender.send(value)) {
            throw;
        }
        return value;
    }

     
     
    function softWithdrawRevenueFor(address forAddress)
        external
        noEther
        returns (uint)
    {
        uint value = calcRevenue(forAddress);
        revenueAtTimeOfWithdraw[forAddress] = totalRevenue;
        owed[forAddress] += value;
        return value;
    }

     
     
    function setup(address singularDTVCrowdfundingAddress, address singularDTVTokenAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(singularDTVCrowdfunding) == 0 && address(singularDTVToken) == 0) {
            singularDTVCrowdfunding = SingularDTVCrowdfunding(singularDTVCrowdfundingAddress);
            singularDTVToken = SingularDTVToken(singularDTVTokenAddress);
            return true;
        }
        return false;
    }

     
    function SingularDTVFund() noEther {
         
        owner = msg.sender;
    }
}