 

pragma solidity 0.4.18;


contract CrowdsaleParameters {
     
     
     
    uint32 internal vestingTime90Days = 1526896800;
    uint32 internal vestingTime180Days = 1534672800;

    uint256 internal constant presaleStartDate = 1513072800;  
    uint256 internal constant presaleEndDate = 1515751200;  
    uint256 internal constant generalSaleStartDate = 1516442400;  
    uint256 internal constant generalSaleEndDate = 1519120800;  

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
        uint256 vestingTS;
    }

    AddressTokenAllocation internal presaleWallet       = AddressTokenAllocation(0x43C5FB6b419E6dF1a021B9Ad205A18369c19F57F, 100e6, 0);
    AddressTokenAllocation internal generalSaleWallet   = AddressTokenAllocation(0x0635c57CD62dA489f05c3dC755bAF1B148FeEdb0, 550e6, 0);
    AddressTokenAllocation internal wallet1             = AddressTokenAllocation(0xae46bae68D0a884812bD20A241b6707F313Cb03a,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet2             = AddressTokenAllocation(0xfe472389F3311e5ea19B4Cd2c9945b6D64732F13,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet3             = AddressTokenAllocation(0xE37dfF409AF16B7358Fae98D2223459b17be0B0B,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet4             = AddressTokenAllocation(0x39482f4cd374D0deDD68b93eB7F3fc29ae7105db,  10e6, vestingTime180Days);
    AddressTokenAllocation internal wallet5             = AddressTokenAllocation(0x03736d5B560fE0784b0F5c2D0eA76A7F15E5b99e,   5e6, vestingTime180Days);
    AddressTokenAllocation internal wallet6             = AddressTokenAllocation(0xD21726226c32570Ab88E12A9ac0fb2ed20BE88B9,   5e6, vestingTime180Days);
    AddressTokenAllocation internal foundersWallet      = AddressTokenAllocation(0xC66Cbb7Ba88F120E86920C0f85A97B2c68784755,  30e6, vestingTime90Days);
    AddressTokenAllocation internal wallet7             = AddressTokenAllocation(0x24ce108d1975f79B57c6790B9d4D91fC20DEaf2d,   6e6, 0);
    AddressTokenAllocation internal wallet8genesis      = AddressTokenAllocation(0x0125c6Be773bd90C0747012f051b15692Cd6Df31,   5e6, 0);
    AddressTokenAllocation internal wallet9             = AddressTokenAllocation(0xFCF0589B6fa8A3f262C4B0350215f6f0ed2F630D,   5e6, 0);
    AddressTokenAllocation internal wallet10            = AddressTokenAllocation(0x0D016B233e305f889BC5E8A0fd6A5f99B07F8ece,   4e6, 0);
    AddressTokenAllocation internal wallet11bounty      = AddressTokenAllocation(0x68433cFb33A7Fdbfa74Ea5ECad0Bc8b1D97d82E9,  19e6, 0);
    AddressTokenAllocation internal wallet12            = AddressTokenAllocation(0xd620A688adA6c7833F0edF48a45F3e39480149A6,   4e6, 0);
    AddressTokenAllocation internal wallet13rsv         = AddressTokenAllocation(0x8C393F520f75ec0F3e14d87d67E95adE4E8b16B1, 100e6, 0);
    AddressTokenAllocation internal wallet14partners    = AddressTokenAllocation(0x6F842b971F0076C4eEA83b051523d76F098Ffa52,  96e6, 0);
    AddressTokenAllocation internal wallet15lottery     = AddressTokenAllocation(0xcaA48d91D49f5363B2974bb4B2DBB36F0852cf83,   1e6, 0);

    uint256 public minimumICOCap = 3333;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TKLNToken is Owned, CrowdsaleParameters {
    string public standard = 'Token 0.1';
    string public name = 'Taklimakan';
    string public symbol = 'TKLN';
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    bool public transfersEnabled = true;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function approvePresale(address _presaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function toggleTransfers(bool _enable) external;
    function closePresale() external;
    function closeGeneralSale() external;
}

contract TaklimakanCrowdsale is Owned, CrowdsaleParameters {
     
    address internal saleWalletAddress;
    uint private tokenMultiplier = 10;
    uint public saleStartTimestamp;
    uint public saleStopTimestamp;
    uint public saleGoal;
    uint8 public stageBonus;
    bool public goalReached = false;

     
    TKLNToken private token;
    uint public totalCollected = 0;
    mapping (address => uint256) private investmentRecords;

     
    event TokenSale(address indexed tokenReceiver, uint indexed etherAmount, uint indexed tokenAmount, uint tokensPerEther);
    event FundTransfer(address indexed from, address indexed to, uint indexed amount);
    event Refund(address indexed backer, uint amount);

     
    function TaklimakanCrowdsale(address _tokenAddress) public {
        token = TKLNToken(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** token.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleWallet.addr;

        saleStartTimestamp = CrowdsaleParameters.generalSaleStartDate;
        saleStopTimestamp = CrowdsaleParameters.generalSaleEndDate;

         
        saleGoal = CrowdsaleParameters.generalSaleWallet.amount;
        stageBonus = 1;
    }

     
    function isICOActive() public constant returns (bool active) {
        active = ((saleStartTimestamp <= now) && (now < saleStopTimestamp) && (!goalReached));
        return active;
    }

     
    function processPayment(address bakerAddress, uint amount) internal {
        require(isICOActive());

         
         
        assert(msg.value > 0 finney);

         
        FundTransfer(bakerAddress, address(this), amount);

         
        uint tokensPerEth = 16500;

        if (amount < 3 ether)
            tokensPerEth = 15000;
        else if (amount < 7 ether)
            tokensPerEth = 15150;
        else if (amount < 15 ether)
            tokensPerEth = 15300;
        else if (amount < 30 ether)
            tokensPerEth = 15450;
        else if (amount < 75 ether)
            tokensPerEth = 15600;
        else if (amount < 150 ether)
            tokensPerEth = 15750;
        else if (amount < 250 ether)
            tokensPerEth = 15900;
        else if (amount < 500 ether)
            tokensPerEth = 16050;
        else if (amount < 750 ether)
            tokensPerEth = 16200;
        else if (amount < 1000 ether)
            tokensPerEth = 16350;

        tokensPerEth = tokensPerEth * stageBonus;

         
         
        uint tokenAmount = amount * tokensPerEth / 1e18;

         
         
        uint remainingTokenBalance = token.balanceOf(saleWalletAddress) / tokenMultiplier;
        if (remainingTokenBalance < tokenAmount) {
            tokenAmount = remainingTokenBalance;
            goalReached = true;
        }

         
         
        uint acceptedAmount = tokenAmount * 1e18 / tokensPerEth;

         
        token.transferFrom(saleWalletAddress, bakerAddress, tokenAmount * tokenMultiplier);
        TokenSale(bakerAddress, amount, tokenAmount, tokensPerEth);

         
        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (bakerAddress.send(change)) {
                FundTransfer(address(this), bakerAddress, change);
            }
            else revert();
        }

         
        investmentRecords[bakerAddress] += acceptedAmount;
        totalCollected += acceptedAmount;
    }

     
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);
        require(!isICOActive());

        if (owner.send(amount)) {
            FundTransfer(address(this), msg.sender, amount);
        }
    }

     
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

     
    function kill() external onlyOwner {
        require(!isICOActive());
        selfdestruct(owner);
    }

     
    function refund() external {
        require((now > saleStopTimestamp) && (totalCollected < CrowdsaleParameters.minimumICOCap * 1e18));
        require(investmentRecords[msg.sender] > 0);

        var amountToReturn = investmentRecords[msg.sender];

        require(this.balance >= amountToReturn);

        investmentRecords[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
        Refund(msg.sender, amountToReturn);
    }
}

contract TaklimakanPreICO is TaklimakanCrowdsale {
     
    function TaklimakanPreICO(address _tokenAddress) TaklimakanCrowdsale(_tokenAddress) public {
        saleWalletAddress = CrowdsaleParameters.presaleWallet.addr;

        saleStartTimestamp = CrowdsaleParameters.presaleStartDate;
        saleStopTimestamp = CrowdsaleParameters.presaleEndDate;

         
        saleGoal = CrowdsaleParameters.presaleWallet.amount;
        stageBonus = 2;
    }

     
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);

        if (owner.send(amount)) {
            FundTransfer(address(this), msg.sender, amount);
        }
    }

     
    function refund() external {
        revert();
    }
}