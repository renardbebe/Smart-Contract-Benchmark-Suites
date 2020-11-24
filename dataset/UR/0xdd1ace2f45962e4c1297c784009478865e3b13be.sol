 

 

 
 
 
 

 
 
 
 

 
 

pragma solidity ^0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

 
 
 
 

 
 
 
 

 
 

pragma solidity ^0.4.13;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

 

 

 
 
 

pragma solidity ^0.4.8;

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

 
contract ViewlyMainSale is DSAuth, DSMath {

     

    uint public minContributionAmount = 5 ether;  
    uint public maxTotalAmount = 4300 ether;      
    address public beneficiary;                   
    uint public startBlock;                       
    uint public endBlock;                         

    uint public totalContributedAmount;           
    uint public totalRefundedAmount;              

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refunds;

    bool public whitelistRequired;
    mapping(address => bool) public whitelist;


     

    event LogContribute(address contributor, uint amount);
    event LogRefund(address contributor, uint amount);
    event LogCollectAmount(uint amount);


     

    modifier saleOpen() {
        require(block.number >= startBlock);
        require(block.number <= endBlock);
        _;
    }

    modifier requireWhitelist() {
        if (whitelistRequired) require(whitelist[msg.sender]);
        _;
    }


     

    function ViewlyMainSale(address beneficiary_) public {
        beneficiary = beneficiary_;
    }

    function() public payable {
        contribute();
    }


     

    function refund(address contributor) public auth {
        uint amount = contributions[contributor];
        require(amount > 0);
        require(amount <= this.balance);

        contributions[contributor] = 0;
        refunds[contributor] += amount;
        totalRefundedAmount += amount;
        totalContributedAmount -= amount;
        contributor.transfer(amount);
        LogRefund(contributor, amount);
    }

    function setMinContributionAmount(uint minAmount) public auth {
        require(minAmount > 0);

        minContributionAmount = minAmount;
    }

    function setMaxTotalAmount(uint maxAmount) public auth {
        require(maxAmount > 0);

        maxTotalAmount = maxAmount;
    }

    function initSale(uint startBlock_, uint endBlock_) public auth {
        require(startBlock_ > 0);
        require(endBlock_ > startBlock_);

        startBlock = startBlock_;
        endBlock   = endBlock_;
    }

    function collectAmount(uint amount) public auth {
        require(this.balance >= amount);

        beneficiary.transfer(amount);
        LogCollectAmount(amount);
    }

    function addToWhitelist(address[] contributors) public auth {
        require(contributors.length != 0);

        for (uint i = 0; i < contributors.length; i++) {
          whitelist[contributors[i]] = true;
        }
    }

    function removeFromWhitelist(address[] contributors) public auth {
        require(contributors.length != 0);

        for (uint i = 0; i < contributors.length; i++) {
          whitelist[contributors[i]] = false;
        }
    }

    function setWhitelistRequired(bool setting) public auth {
        whitelistRequired = setting;
    }

    function setOwner(address owner_) public auth {
        revert();
    }

    function setAuthority(DSAuthority authority_) public auth {
        revert();
    }

    function recoverTokens(address token_) public auth {
        ERC20 token = ERC20(token_);
        token.transfer(beneficiary, token.balanceOf(this));
    }


     

    function contribute() private saleOpen requireWhitelist {
        require(msg.value >= minContributionAmount);
        require(maxTotalAmount >= add(totalContributedAmount, msg.value));

        contributions[msg.sender] += msg.value;
        totalContributedAmount += msg.value;
        LogContribute(msg.sender, msg.value);
    }
}