 

pragma solidity ^0.4.16;


 
 
 
 
 
 
 

 
 
 

 
 
 
 
 
 

 
 

 
 

 
 

 
 
 
 
 
 
 



 
contract SafeMath {
     function safeMul(uint a, uint b) internal pure returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal pure returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal pure returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}

 
 
contract Token is SafeMath {
      
      

     function totalSupply() public constant returns (uint256 supply);

      
      

     function balanceOf(address _owner) public constant returns (uint256 balance);

      
      
      

     function transfer(address _to, uint256 _value) public returns(bool);

      
      
      
      
      

     function transferFrom(address _from, address _to, uint256 _value) public returns(bool);

      
      
      
      

     function approve(address _spender, uint256 _value) public returns (bool success);

      
      
      

     function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

      
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StdToken is Token {
      
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public supply = 0;   

      
     function transfer(address _to, uint256 _value) public returns(bool) {
          require(balances[msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[msg.sender] = safeSub(balances[msg.sender],_value);
          balances[_to] = safeAdd(balances[_to],_value);

          Transfer(msg.sender, _to, _value);
          return true;
     }

     function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
          require(balances[_from] >= _value);
          require(allowed[_from][msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[_to] = safeAdd(balances[_to],_value);
          balances[_from] = safeSub(balances[_from],_value);
          allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

          Transfer(_from, _to, _value);
          return true;
     }

     function totalSupply() public constant returns (uint256) {
          return supply;
     }

     function balanceOf(address _owner) public constant returns (uint256) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) public returns (bool) {
           
           
           
           
          require((_value == 0) || (allowed[msg.sender][_spender] == 0));

          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);

          return true;
     }

     function allowance(address _owner, address _spender) public constant returns (uint256) {
          return allowed[_owner][_spender];
     }
}



contract LotusToken is StdToken {
    struct Sale {
        uint tokenLimit;
        uint tokenPriceInWei;
        uint tokensSold;
        uint minPurchaseInWei;
        uint maxPurchaseInWei;
        uint saleLimitPerAddress;
    }

    struct Signatory {
        address account;
        bool signed;
    }

    struct SaleTotals {
        uint earlyAdoptersSold;
        uint icoOneSold;
        uint icoTwoSold;
    }

    string public name = "Lotus Token Inc";
    string public symbol = "LTO";
    uint public decimals = 18;

     
     
    address private owner;

     
     
    uint public cliff = 0;
     
    uint private vestingSchedule = 30 days;  
     

     
     
    address public vc1Wallet4Pct;
    address public vc2Wallet4Pct;
    address public vc3Wallet4Pct;

     
    address public cf1Wallet2Pct;
    address public cf2Wallet2Pct;

     
    address public dev1Wallet2Pct;
    address public dev2Wallet2Pct;
    address public dev3Wallet2Pct;
    address public dev4Wallet2Pct;

     
    address public preicobrandingWallet1Pct;

     
    address public lotusWallet75Pct;

     
    address public airdropWallet5Pct;

     
    uint public tokensSold = 0;

     
    mapping(address => uint256) internal ethDistribution;

     
    mapping(address => uint256) private vestingTokens;
    mapping(address => uint256) private withdrawnVestedTokens;

    Sale public EARLYADOPTERS;
    Sale public ICO_ONE;
    Sale public ICO_TWO;

     
    mapping(address => uint256) private earlyAdoptersAddressPurchased;
    mapping(address => uint256) private icoOneAddressPurchased;
    mapping(address => uint256) private icoTwoAddressPurchased;

    enum SaleStage { Waiting, EarlyAdopters, EarlyAdoptersClosed,  IcoOne, IcoOneClosed, IcoTwo, Closed }
    SaleStage currentStage = SaleStage.Waiting;

     
    function LotusToken(address _shareholder1Account,
                        address _shareholder2Account,
                        address _shareholder3Account,

                         
                        address _core1Account,
                        address _core2Account,

                         
                        address _dev1Account,
                        address _dev2Account,
                        address _dev3Account,
                        address _dev4Account,

                         
                        address _brandingAccount,

                         
                        address _lotusTokenAccount,

                         
                        address _airdropContractAccount

    ) public {
         
        owner = msg.sender;

         
         
        supply = 90000000 * 10 ** decimals;

         

         
         
         
         
         
         
         
         
         
         
         
        uint earlyAdoptersSupply = (supply * 10 / 100);  
         
        EARLYADOPTERS = Sale(earlyAdoptersSupply, 166666666666667, 0, 2 * 10 ** 17, 5 * 10 ** 18, 59990000000000000000000);

         
         
         
         
         
         
         
         
         
         
         
        ICO_ONE = Sale(supply * 15 / 100, 266666666666666, 0, 2 * 10 ** 17, 10 * 10 ** 18, 67500000000000000000000);

         
         
         
         
         
         
         
         
         
         
         
        ICO_TWO = Sale(supply * 15 / 100, 333333333333334, 0, 2 * 10 ** 17, 20 * 10 ** 18, 75000000000000000000000);

         
        require(safeAdd(safeAdd(EARLYADOPTERS.tokenLimit, ICO_ONE.tokenLimit), ICO_ONE.tokenLimit)  <= supply);

         
        ethDistribution[0X0] = 0;

         
        vc1Wallet4Pct = _shareholder1Account;
        vc2Wallet4Pct = _shareholder2Account;
        vc3Wallet4Pct = _shareholder3Account;

         
        cf1Wallet2Pct = _core1Account;
        cf2Wallet2Pct = _core2Account;

         
        dev1Wallet2Pct = _dev1Account;
        dev2Wallet2Pct = _dev2Account;
        dev3Wallet2Pct = _dev3Account;
        dev4Wallet2Pct = _dev4Account;

         
        preicobrandingWallet1Pct = _brandingAccount;

        lotusWallet75Pct = _lotusTokenAccount;  
         
         
         
         

        airdropWallet5Pct = _airdropContractAccount;  
    }

     
    modifier mustBeSelling {
        require(currentStage == SaleStage.EarlyAdopters || currentStage == SaleStage.IcoOne || currentStage == SaleStage.IcoTwo);
        _;
    }

    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function () public payable mustBeSelling {
         
        require(msg.value > 0);

         
        require(msg.value >= currentMinPurchase() && msg.value <= currentMaxPurchase());


         
        uint priceNow = currentSalePriceInWei();
         
        uint currentLimit = currentSaleLimit();
         
        uint currentSold = currentSaleSold();
         
        uint currentLimitPerAddress = currentSaleLimitPerAddress();
         
        uint currentStageTokensBought = currentStageTokensBoughtByAddress();

         
        uint priceInWei = msg.value;

         
        uint tokensAtPrice = (priceInWei / priceNow) * 10 ** decimals;      

         
         
        require(tokensAtPrice + currentSold <= currentLimit);

         
        require(tokensAtPrice + currentStageTokensBought <= currentLimitPerAddress);

         
        balances[msg.sender] = safeAdd(balances[msg.sender], tokensAtPrice);   
        tokensSold = safeAdd(tokensSold, tokensAtPrice);  

         
        _addTokensSoldToCurrentSale(tokensAtPrice);

         
        distributeCollectedEther();

         
        Transfer(this, msg.sender, tokensAtPrice);
    }

     
     
     
    function distributeCollectedEther() internal {

     

     
     
     

     
     
     
        ethDistribution[vc1Wallet4Pct] = safeAdd(ethDistribution[vc1Wallet4Pct], msg.value * 4 / 100);
        ethDistribution[vc2Wallet4Pct] = safeAdd(ethDistribution[vc2Wallet4Pct], msg.value * 4 / 100);
        ethDistribution[vc3Wallet4Pct] = safeAdd(ethDistribution[vc3Wallet4Pct], msg.value * 4 / 100);

     
        ethDistribution[cf1Wallet2Pct] = safeAdd(ethDistribution[cf1Wallet2Pct], msg.value * 2 / 100);
        ethDistribution[cf2Wallet2Pct] = safeAdd(ethDistribution[cf2Wallet2Pct], msg.value * 2 / 100);

     
        ethDistribution[dev1Wallet2Pct] = safeAdd(ethDistribution[dev1Wallet2Pct], msg.value * 2 / 100);
        ethDistribution[dev3Wallet2Pct] = safeAdd(ethDistribution[dev3Wallet2Pct], msg.value * 2 / 100);
        ethDistribution[dev2Wallet2Pct] = safeAdd(ethDistribution[dev2Wallet2Pct], msg.value * 2 / 100);
        ethDistribution[dev4Wallet2Pct] = safeAdd(ethDistribution[dev4Wallet2Pct], msg.value * 2 / 100);

     
        ethDistribution[preicobrandingWallet1Pct] = safeAdd(ethDistribution[preicobrandingWallet1Pct], msg.value * 1 / 100);

     
        ethDistribution[lotusWallet75Pct] = safeAdd(ethDistribution[lotusWallet75Pct], msg.value * 75 / 100);
    }

     
    function distributeRemainingTokens() internal ownerOnly {
         
        uint crowdsaleSupply = supply * 40 / 100;
        uint unsoldTokens = crowdsaleSupply - tokensSold;

         
         
        balances[lotusWallet75Pct] = safeAdd(balances[lotusWallet75Pct], unsoldTokens * 75 / 100);
        Transfer(this, lotusWallet75Pct, unsoldTokens * 75 / 100);

         
         
         
         
         
        balances[vc1Wallet4Pct] = safeAdd(balances[vc1Wallet4Pct],  unsoldTokens * 4 / 100 * 25 / 100);
        Transfer(this, vc1Wallet4Pct, unsoldTokens * 4 / 100 * 25 / 100);
         
        vestingTokens[vc1Wallet4Pct] = safeAdd(vestingTokens[vc1Wallet4Pct], unsoldTokens * 4 / 100 * 75 / 100);

         
        balances[vc2Wallet4Pct] = safeAdd(balances[vc2Wallet4Pct], unsoldTokens * 4 / 100 * 25 / 100);
        Transfer(this, vc2Wallet4Pct, unsoldTokens * 4 / 100 * 25 / 100);
         
        vestingTokens[vc2Wallet4Pct] = safeAdd(vestingTokens[vc2Wallet4Pct], unsoldTokens * 4 / 100 * 75 / 100);

         
        balances[vc3Wallet4Pct] = safeAdd(balances[vc3Wallet4Pct], unsoldTokens * 4 / 100 * 25 / 100);
        Transfer(this, vc3Wallet4Pct, unsoldTokens * 4 / 100 * 25 / 100);
         
        vestingTokens[vc3Wallet4Pct] = safeAdd(vestingTokens[vc3Wallet4Pct], unsoldTokens * 4 / 100 * 75 / 100);

         
        balances[cf1Wallet2Pct] = safeAdd(balances[cf1Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, cf1Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[cf1Wallet2Pct] = safeAdd(vestingTokens[cf1Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
        balances[cf2Wallet2Pct] = safeAdd(balances[cf2Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, cf2Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[cf2Wallet2Pct] = safeAdd(vestingTokens[cf2Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
        balances[dev1Wallet2Pct] = safeAdd(balances[dev1Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, dev1Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[dev1Wallet2Pct] = safeAdd(vestingTokens[dev1Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
        balances[dev2Wallet2Pct] = safeAdd(balances[dev2Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, dev2Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[dev2Wallet2Pct] = safeAdd(vestingTokens[dev2Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
        balances[dev3Wallet2Pct] = safeAdd(balances[dev3Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, dev3Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[dev3Wallet2Pct] = safeAdd(vestingTokens[dev3Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
        balances[preicobrandingWallet1Pct] = safeAdd(balances[preicobrandingWallet1Pct], unsoldTokens * 1 / 100 * 25 / 100);
        Transfer(this, preicobrandingWallet1Pct, unsoldTokens * 1 / 100  * 25 / 100);
         
        vestingTokens[preicobrandingWallet1Pct] = safeAdd(vestingTokens[preicobrandingWallet1Pct], unsoldTokens * 1 / 100 * 75 / 100);

         
        balances[dev4Wallet2Pct] = safeAdd(balances[dev4Wallet2Pct], unsoldTokens * 2 / 100 * 25 / 100);
        Transfer(this, dev4Wallet2Pct, unsoldTokens * 2 / 100 * 25 / 100);
         
        vestingTokens[dev4Wallet2Pct] = safeAdd(vestingTokens[dev4Wallet2Pct], unsoldTokens * 2 / 100 * 75 / 100);

         
         
         
         

         
        uint reservedSupply = supply * 55 / 100;

         
         
         
        balances[lotusWallet75Pct] = safeAdd(balances[lotusWallet75Pct], reservedSupply);
        Transfer(this, lotusWallet75Pct, reservedSupply);

         
        uint airdropSupply = supply * 5 / 100;
         
        balances[airdropWallet5Pct] = safeAdd(balances[airdropWallet5Pct], airdropSupply);
        Transfer(this, airdropWallet5Pct, airdropSupply);
    }

    function startEarlyAdopters() public ownerOnly {
        require(currentStage == SaleStage.Waiting);
        currentStage = SaleStage.EarlyAdopters;
    }

    function closeEarlyAdopters() public ownerOnly {
        require(currentStage == SaleStage.EarlyAdopters);
        currentStage = SaleStage.EarlyAdoptersClosed;
    }

    function startIcoOne() public ownerOnly {
        require(currentStage == SaleStage.EarlyAdopters || currentStage == SaleStage.EarlyAdoptersClosed);
        currentStage = SaleStage.IcoOne;
    }

    function closeIcoOne() public ownerOnly {
        require(currentStage == SaleStage.IcoOne);
        currentStage = SaleStage.IcoOneClosed;
    }

    function startIcoTwo() public ownerOnly {
        require(currentStage == SaleStage.IcoOne || currentStage == SaleStage.IcoOneClosed);
        currentStage = SaleStage.IcoTwo;

         
         
         

    }

    function closeSale() public ownerOnly {
        require(currentStage == SaleStage.IcoTwo);
        currentStage = SaleStage.Closed;
        distributeRemainingTokens();  
         
        cliff = now + 180 days;  
         
    }

    modifier doneSelling {
        require(currentStage == SaleStage.Closed);
        _;
    }

     
    function withdrawAllocation() public {
         
         
         
         
         
         
         

         
        require(ethDistribution[msg.sender] > 0);
         
        require(currentStage == SaleStage.EarlyAdoptersClosed || currentStage == SaleStage.IcoOneClosed || currentStage == SaleStage.Closed);
         
        require(msg.sender != lotusWallet75Pct || currentStage == SaleStage.Closed);


         
         
        uint toTransfer = ethDistribution[msg.sender];
         
        ethDistribution[msg.sender] = 0;

         
        msg.sender.transfer(toTransfer);
    }

    function currentSalePriceInWei() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.tokenPriceInWei;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.tokenPriceInWei;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.tokenPriceInWei;
        }
    }


    function currentSaleLimit() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.tokenLimit;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.tokenLimit;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.tokenLimit;
        }
    }

    function currentSaleSold() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.tokensSold;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.tokensSold;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.tokensSold;
        }
    }

    function currentMinPurchase() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.minPurchaseInWei;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.minPurchaseInWei;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.minPurchaseInWei;
        }
    }

    function currentMaxPurchase() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.maxPurchaseInWei;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.maxPurchaseInWei;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.maxPurchaseInWei;
        }
    }

    function currentSaleLimitPerAddress() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return EARLYADOPTERS.saleLimitPerAddress;
        } else if (currentStage == SaleStage.IcoOne) {
            return ICO_ONE.saleLimitPerAddress;
        } else if (currentStage == SaleStage.IcoTwo) {
            return ICO_TWO.saleLimitPerAddress;
        }
    }

    function currentStageTokensBoughtByAddress() constant public mustBeSelling returns(uint) {
        if(currentStage == SaleStage.EarlyAdopters) {
            return earlyAdoptersAddressPurchased[msg.sender];
        } else if (currentStage == SaleStage.IcoOne) {
            return icoOneAddressPurchased[msg.sender];
        } else if (currentStage == SaleStage.IcoTwo) {
            return icoTwoAddressPurchased[msg.sender];
        }
    }

    function _addTokensSoldToCurrentSale(uint _additionalTokensSold) internal mustBeSelling {
        if(currentStage == SaleStage.EarlyAdopters) {
            EARLYADOPTERS.tokensSold = safeAdd(EARLYADOPTERS.tokensSold, _additionalTokensSold);
            earlyAdoptersAddressPurchased[msg.sender] = safeAdd(earlyAdoptersAddressPurchased[msg.sender], _additionalTokensSold);
        } else if (currentStage == SaleStage.IcoOne) {
            ICO_ONE.tokensSold = safeAdd(ICO_ONE.tokensSold, _additionalTokensSold);
            icoOneAddressPurchased[msg.sender] = safeAdd(icoOneAddressPurchased[msg.sender], _additionalTokensSold);
        } else if (currentStage == SaleStage.IcoTwo) {
            ICO_TWO.tokensSold = safeAdd(ICO_TWO.tokensSold, _additionalTokensSold);
            icoTwoAddressPurchased[msg.sender] = safeAdd(icoTwoAddressPurchased[msg.sender], _additionalTokensSold);
        }
    }

    function withdrawVestedTokens() public doneSelling {
         
         
        require(cliff > 0);
         
        require(now >= cliff);
         
        require(withdrawnVestedTokens[msg.sender] < vestingTokens[msg.sender]);

         
         
        uint schedulesPassed = ((now - cliff) / vestingSchedule) + 1;
         
        uint vestedTokens = (vestingTokens[msg.sender] / 15) * schedulesPassed;
         
        uint availableToWithdraw = vestedTokens - withdrawnVestedTokens[msg.sender];
         
        withdrawnVestedTokens[msg.sender] = safeAdd(withdrawnVestedTokens[msg.sender], availableToWithdraw);
         
        balances[msg.sender] = safeAdd(balances[msg.sender], availableToWithdraw);
        Transfer(this, msg.sender, availableToWithdraw);
    }
}