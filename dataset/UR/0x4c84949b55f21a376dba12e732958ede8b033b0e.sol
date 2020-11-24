 

pragma solidity ^0.4.18;

 
 
 
 
 
contract TokenVesting {
    using SafeMath for uint256;


     
    struct VestingGrant {
        bool isGranted;                                                  
        address issuer;                                                  
        address beneficiary;                                             
        uint256 grantJiffys;                                             
        uint256 startTimestamp;                                          
        uint256 cliffTimestamp;                                          
        uint256 endTimestamp;                                            
        bool isRevocable;                                                
        uint256 releasedJiffys;                                          
    }

    mapping(address => VestingGrant) private vestingGrants;              
    address[] private vestingGrantLookup;                                

    uint private constant GENESIS_TIMESTAMP = 1514764800;                        
    uint private constant ONE_MONTH = 2629743;
    uint private constant ONE_YEAR = 31556926;
    uint private constant TWO_YEARS = 63113852;
    uint private constant THREE_YEARS = 94670778;

    bool private initialized = false;

     
    event Grant              
                            (
                                address indexed owner, 
                                address indexed beneficiary, 
                                uint256 valueVested,
                                uint256 valueUnvested
                            );

    event Revoke             
                            (
                                address indexed owner, 
                                address indexed beneficiary, 
                                uint256 value
                            );

     
    function() public {
        revert();
    }

    string public name = "TokenVesting";

     
    WHENToken whenContract;

    modifier requireIsOperational() 
    {
        require(whenContract.isOperational());
        _;
    }

     
    function TokenVesting
                                (
                                    address whenTokenContract
                                ) 
                                public
    {
        whenContract = WHENToken(whenTokenContract);

    }

          
    function initialize         (
                                    address companyAccount,
                                    address partnerAccount, 
                                    address foundationAccount
                                )
                                external
    {
        require(!initialized);

        initialized = true;

        uint256 companyJiffys;
        uint256 partnerJiffys;
        uint256 foundationJiffys;
        (companyJiffys, partnerJiffys, foundationJiffys) = whenContract.getTokenAllocations();

         
         
        uint256 companyInitialGrant = companyJiffys.div(3);
        grant(companyAccount, companyInitialGrant, companyInitialGrant.mul(2), GENESIS_TIMESTAMP + ONE_YEAR, 0, TWO_YEARS, false);

         
         
        grant(partnerAccount, 0, partnerJiffys, GENESIS_TIMESTAMP, ONE_MONTH.mul(6), THREE_YEARS, true);

         
         
        grant(foundationAccount, 0, foundationJiffys, GENESIS_TIMESTAMP, ONE_MONTH.mul(6), THREE_YEARS, true);
    }

        
    function grant
                            (
                                address beneficiary, 
                                uint256 vestedJiffys,
                                uint256 unvestedJiffys, 
                                uint256 startTimestamp, 
                                uint256 cliffSeconds, 
                                uint256 vestingSeconds, 
                                bool revocable
                            ) 
                            public 
                            requireIsOperational
    {
        require(beneficiary != address(0));
        require(!vestingGrants[beneficiary].isGranted);          
        require((vestedJiffys > 0) || (unvestedJiffys > 0));     

        require(startTimestamp >= GENESIS_TIMESTAMP);            
        require(vestingSeconds > 0);
        require(cliffSeconds >= 0);
        require(cliffSeconds < vestingSeconds);

        whenContract.vestingGrant(msg.sender, beneficiary, vestedJiffys, unvestedJiffys);

         
        vestingGrants[beneficiary] = VestingGrant({
                                                    isGranted: true,
                                                    issuer: msg.sender,                                                   
                                                    beneficiary: beneficiary, 
                                                    grantJiffys: unvestedJiffys,
                                                    startTimestamp: startTimestamp,
                                                    cliffTimestamp: startTimestamp + cliffSeconds,
                                                    endTimestamp: startTimestamp + vestingSeconds,
                                                    isRevocable: revocable,
                                                    releasedJiffys: 0
                                                });

        vestingGrantLookup.push(beneficiary);

        Grant(msg.sender, beneficiary, vestedJiffys, unvestedJiffys);    

         
         
        if (vestingGrants[beneficiary].cliffTimestamp <= now) {
            releaseFor(beneficiary);
        }
    }

      
    function getGrantBalance() 
                            external 
                            view 
                            returns(uint256) 
    {
       return getGrantBalanceOf(msg.sender);        
    }

      
    function getGrantBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(uint256) 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        
        return(vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys));
    }


      
    function release() 
                            public 
    {
        releaseFor(msg.sender);
    }

      
    function releaseFor
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        require(vestingGrants[account].cliffTimestamp <= now);
        
         
        uint256 jiffysPerSecond = (vestingGrants[account].grantJiffys.div(vestingGrants[account].endTimestamp.sub(vestingGrants[account].startTimestamp)));

         
        uint256 releasableJiffys = now.sub(vestingGrants[account].startTimestamp).mul(jiffysPerSecond).sub(vestingGrants[account].releasedJiffys);

         
         
        if ((vestingGrants[account].releasedJiffys.add(releasableJiffys)) > vestingGrants[account].grantJiffys) {
            releasableJiffys = vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys);
        }

        if (releasableJiffys > 0) {
             
            vestingGrants[account].releasedJiffys = vestingGrants[account].releasedJiffys.add(releasableJiffys);
            whenContract.vestingTransfer(vestingGrants[account].issuer, account, releasableJiffys);
        }
    }

      
    function getGrantBeneficiaries() 
                            external 
                            view 
                            returns(address[]) 
    {
        return vestingGrantLookup;        
    }

      
    function revoke
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        require(vestingGrants[account].isRevocable);
        require(vestingGrants[account].issuer == msg.sender);  

         
         
        vestingGrants[account].isGranted = false;        
        
         
        uint256 balanceJiffys = vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys);
        Revoke(vestingGrants[account].issuer, account, balanceJiffys);

         
        if (balanceJiffys > 0) {
            whenContract.vestingTransfer(msg.sender, msg.sender, balanceJiffys);
        }
    }

}

contract WHENToken {

    function isOperational() public view returns(bool);
    function vestingGrant(address owner, address beneficiary, uint256 vestedJiffys, uint256 unvestedJiffys) external;
    function vestingTransfer(address owner, address beneficiary, uint256 jiffys) external;
    function getTokenAllocations() external view returns(uint256, uint256, uint256);
}

 


library SafeMath {
 
 

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
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