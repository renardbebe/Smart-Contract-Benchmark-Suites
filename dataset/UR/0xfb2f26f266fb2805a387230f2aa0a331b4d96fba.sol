 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


pragma solidity ^0.4.11;


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.11;


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.11;


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

pragma solidity ^0.4.11;


 
contract DadiToken is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string public name = "DADI";
    string public symbol = "DADI";
    uint8 public decimals = 18;
    string public version = "H1.0";

    address public owner;

    uint256 public hundredPercent = 1000;
    uint256 public foundersPercentOfTotal = 200;
    uint256 public referralPercentOfTotal = 50;
    uint256 public ecosystemPercentOfTotal = 25;
    uint256 public operationsPercentOfTotal = 25;

    uint256 public investorCount = 0;
    uint256 public totalRaised;  
    uint256 public preSaleRaised = 0;  
    uint256 public publicSaleRaised = 0;  

     
    uint256 public partnerSaleTokensAvailable;
    uint256 public partnerSaleTokensPurchased = 0;
    mapping(address => uint256) public purchasedTokens;
    mapping(address => uint256) public partnerSaleWei;

     
    uint256 public preSaleTokensAvailable;
    uint256 public preSaleTokensPurchased = 0;

     
    uint256 public publicSaleTokensAvailable;
    uint256 public publicSaleTokensPurchased = 0;

     
    uint256 public partnerSaleTokenPrice = 125;      
    uint256 public partnerSaleTokenValue;
    uint256 public preSaleTokenPrice = 250;          
    uint256 public publicSaleTokenPrice = 500;        

     
    uint256 public ethRate;

     
    address public fundsWallet;
    address public ecosystemWallet;
    address public operationsWallet;
    address public referralProgrammeWallet;
    address[] public foundingTeamWallets;
    
    address[] public partnerSaleWallets;
    address[] public preSaleWallets;
    address[] public publicSaleWallets;
   
     
    enum SaleState { Preparing, PartnerSale, PreSale, PublicSale, Success, Failure, PartnerSaleFinalized, PreSaleFinalized, PublicSaleFinalized, Refunding, Closed }
    SaleState public state = SaleState.Preparing;

     
    event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);
    event LogRedistributeTokens(address recipient, SaleState state, uint256 tokens);
    event LogRefundProcessed(address recipient, uint256 value);
    event LogRefundFailed(address recipient, uint256 value);
    event LogClaimTokens(address recipient, uint256 tokens);
    event LogFundTransfer(address wallet, uint256 value);

     
    modifier nonZero() {
        require(msg.value != 0);
        _;
    }

     
    function DadiToken (
        address _wallet,
        address[] _operationalWallets,
        address[] _foundingTeamWallets,
        uint256 _initialSupply,
        uint256[] _tokensAvailable
    ) public {
        require(_wallet != address(0));

        owner = msg.sender;
 
         
        partnerSaleTokensAvailable = _tokensAvailable[0];
        preSaleTokensAvailable = _tokensAvailable[1];
        publicSaleTokensAvailable = _tokensAvailable[2];

         
        totalSupply = _initialSupply * (uint256(10) ** decimals);

         
        balances[owner] = totalSupply;
        Transfer(0x0, owner, totalSupply);

         
        ecosystemWallet = _operationalWallets[0];
        operationsWallet = _operationalWallets[1];
        referralProgrammeWallet = _operationalWallets[2];
        foundingTeamWallets = _foundingTeamWallets;
        fundsWallet = _wallet;
        
         
        updateEthRate(300000);
    }

     
    function () payable {
        require(
            state == SaleState.PartnerSale || 
            state == SaleState.PreSale || 
            state == SaleState.PublicSale
        );

        buyTokens(msg.sender, msg.value);
    }

     
    function offlineTransaction (address _recipient, uint256 _tokens) public onlyOwner returns (bool) {
        require(state == SaleState.PartnerSale);
        require(_tokens > 0);

         
        uint256 tokens = _tokens * (uint256(10) ** decimals);

        purchasedTokens[_recipient] = purchasedTokens[_recipient].add(tokens);

         
        partnerSaleTokensPurchased = partnerSaleTokensPurchased.add(_tokens);

         
        if (partnerSaleTokensPurchased >= partnerSaleTokensAvailable) {
            state = SaleState.PartnerSaleFinalized;
        }

        LogTokenPurchase(msg.sender, _recipient, 0, tokens);

        return true;
    }

     
    function updateEthRate (uint256 rate) public onlyOwner returns (bool) {
        require(rate >= 100000);
        
        ethRate = rate;
        return true;
    }

     
    function addPartnerSaleWallet (address _wallet) public onlyOwner returns (bool) {
        require(state < SaleState.PartnerSaleFinalized);
        require(_wallet != address(0));
        partnerSaleWallets.push(_wallet);
        return true;
    }

     
    function addPreSaleWallet (address _wallet) public onlyOwner returns (bool) {
        require(state != SaleState.PreSale);
        require(_wallet != address(0));
        preSaleWallets.push(_wallet);
        return true;
    }

     
    function addPublicSaleWallet (address _wallet) public onlyOwner returns (bool) {
        require(state != SaleState.PublicSale);
        require(_wallet != address(0));
        publicSaleWallets.push(_wallet);
        return true;
    }

     
    function calculateTokens (uint256 _amount) public returns (uint256 tokens) {
        if (isStatePartnerSale()) {
            tokens = _amount * ethRate / partnerSaleTokenPrice;
        } else if (isStatePreSale()) {
            tokens = _amount * ethRate / preSaleTokenPrice;
        } else if (isStatePublicSale()) {
            tokens = _amount * ethRate / publicSaleTokenPrice;
        } else {
            tokens = 0;
        }

        return tokens;
    }

     
    function setPhase (uint256 phase) public onlyOwner {
        state = SaleState(uint(phase));
    }

     
    function startPartnerSale (uint256 rate) public onlyOwner {
        state = SaleState.PartnerSale;
        updateEthRate(rate);
    }

     
    function startPreSale (uint256 rate) public onlyOwner {
        state = SaleState.PreSale;
        updateEthRate(rate);
    }

     
    function startPublicSale (uint256 rate) public onlyOwner {
        state = SaleState.PublicSale;
        updateEthRate(rate);
    }

     
    function finalizePartnerSale () public onlyOwner {
        require(state == SaleState.PartnerSale);
        
        state = SaleState.PartnerSaleFinalized;
    }

     
    function finalizePreSale () public onlyOwner {
        require(state == SaleState.PreSale);
        
        state = SaleState.PreSaleFinalized;
    }

     
    function finalizePublicSale () public onlyOwner {
        require(state == SaleState.PublicSale);
        
        state = SaleState.PublicSaleFinalized;
    }

     
    function finalizeIco () public onlyOwner {
        require(state == SaleState.PublicSaleFinalized);

        state = SaleState.Success;

         
        distribute(ecosystemWallet, ecosystemPercentOfTotal);

         
        distribute(operationsWallet, operationsPercentOfTotal);

         
        distribute(referralProgrammeWallet, referralPercentOfTotal);
        
         
        distributeFoundingTeamTokens(foundingTeamWallets);

         
        uint256 remainingPreSaleTokens = getPreSaleTokensAvailable();
        preSaleTokensAvailable = 0;
        
        uint256 remainingPublicSaleTokens = getPublicSaleTokensAvailable();
        publicSaleTokensAvailable = 0;

         
         
        if (remainingPreSaleTokens > 0) {
            remainingPreSaleTokens = remainingPreSaleTokens * (uint256(10) ** decimals);
            balances[owner] = balances[owner].sub(remainingPreSaleTokens);
            balances[ecosystemWallet] = balances[ecosystemWallet].add(remainingPreSaleTokens);
            Transfer(0, ecosystemWallet, remainingPreSaleTokens);
        }

        if (remainingPublicSaleTokens > 0) {
            remainingPublicSaleTokens = remainingPublicSaleTokens * (uint256(10) ** decimals);
            balances[owner] = balances[owner].sub(remainingPublicSaleTokens);
            balances[ecosystemWallet] = balances[ecosystemWallet].add(remainingPublicSaleTokens);
            Transfer(0, ecosystemWallet, remainingPublicSaleTokens);
        }

         
        if (!fundsWallet.send(this.balance)) {
            revert();
        }
    }

     
    function closeIco () public onlyOwner {
        state = SaleState.Closed;
    }
    

     
    function claimTokens () public returns (bool) {
        require(state == SaleState.Success);
        
         
        uint256 tokens = purchasedTokens[msg.sender];
        require(tokens > 0);

        purchasedTokens[msg.sender] = 0;

        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
      
        LogClaimTokens(msg.sender, tokens);
        Transfer(owner, msg.sender, tokens);
        return true;
    }

     
    function refund (address _recipient) public onlyOwner returns (bool) {
        require(state == SaleState.Refunding);

        uint256 value = partnerSaleWei[_recipient];
        
        require(value > 0);

        partnerSaleWei[_recipient] = 0;

        if(!_recipient.send(value)) {
            partnerSaleWei[_recipient] = value;
            LogRefundFailed(_recipient, value);
        }

        LogRefundProcessed(_recipient, value);
        return true;
    }

     
    function withdrawFunds (address _address, uint256 _amount) public onlyOwner {
        _address.transfer(_amount);
    }

     
    function getRandom(uint max) public constant returns (uint randomNumber) {
        return (uint(sha3(block.blockhash(block.number - 1))) % max) + 1;
    }

     
    function setRefunding () public onlyOwner {
        require(state == SaleState.PartnerSaleFinalized);
        
        state = SaleState.Refunding;
    }

     
    function isSuccessful () public constant returns (bool) {
        return state == SaleState.Success;
    }

     
    function getPreSaleTokensAvailable () public constant returns (uint256) {
        if (preSaleTokensAvailable == 0) {
            return 0;
        }

        return preSaleTokensAvailable - preSaleTokensPurchased;
    }

     
    function getPublicSaleTokensAvailable () public constant returns (uint256) {
        if (publicSaleTokensAvailable == 0) {
            return 0;
        }

        return publicSaleTokensAvailable - publicSaleTokensPurchased;
    }

     
    function getTokensPurchased () public constant returns (uint256) {
        return partnerSaleTokensPurchased + preSaleTokensPurchased + publicSaleTokensPurchased;
    }

     
    function getTotalRaised () public constant returns (uint256) {
        return preSaleRaised + publicSaleRaised;
    }

     
    function getBalance () public constant returns (uint256) {
        return this.balance;
    }

     
    function getFundsWalletBalance () public constant onlyOwner returns (uint256) {
        return fundsWallet.balance;
    }

     
    function getInvestorCount () public constant returns (uint256) {
        return investorCount;
    }

     
    function forwardFunds (uint256 _value) internal {
         
         
         
         
         
         
         
         
         
         

        uint accountNumber;
        address account;

        if (isStatePreSale()) {
             
            if (preSaleWallets.length > 0) {
                 
                accountNumber = getRandom(preSaleWallets.length) - 1;
                account = preSaleWallets[accountNumber];
                account.transfer(_value);
                LogFundTransfer(account, _value);
            }
        } else if (isStatePublicSale()) {
             
            if (publicSaleWallets.length > 0) {
                 
                accountNumber = getRandom(publicSaleWallets.length) - 1;
                account = publicSaleWallets[accountNumber];
                account.transfer(_value);
                LogFundTransfer(account, _value);
            }
        }
    }

     
    function buyTokens (address _recipient, uint256 _value) internal returns (bool) {
        uint256 boughtTokens = calculateTokens(_value);
        require(boughtTokens != 0);

        if (isStatePartnerSale()) {
             
            purchasedTokens[_recipient] = purchasedTokens[_recipient].add(boughtTokens);
            partnerSaleWei[_recipient] = partnerSaleWei[_recipient].add(_value);
        } else {
             
            if (purchasedTokens[_recipient] == 0) {
                investorCount++;
            }

             
            purchasedTokens[_recipient] = purchasedTokens[_recipient].add(boughtTokens);
        }

       
        LogTokenPurchase(msg.sender, _recipient, _value, boughtTokens);

        forwardFunds(_value);

        updateSaleParameters(_value, boughtTokens);

        return true;
    }

     
    function updateSaleParameters (uint256 _value, uint256 _tokens) internal returns (bool) {
         
         
        uint256 tokens = _tokens / (uint256(10) ** decimals);

        if (isStatePartnerSale()) {
            partnerSaleTokensPurchased = partnerSaleTokensPurchased.add(tokens);

             
            if (partnerSaleTokensPurchased >= partnerSaleTokensAvailable) {
                state = SaleState.PartnerSaleFinalized;
            }
        } else if (isStatePreSale()) {
            preSaleTokensPurchased = preSaleTokensPurchased.add(tokens);

            preSaleRaised = preSaleRaised.add(_value);

             
            if (preSaleTokensPurchased >= preSaleTokensAvailable) {
                state = SaleState.PreSaleFinalized;
            }
        } else if (isStatePublicSale()) {
            publicSaleTokensPurchased = publicSaleTokensPurchased.add(tokens);

            publicSaleRaised = publicSaleRaised.add(_value);

             
            if (publicSaleTokensPurchased >= publicSaleTokensAvailable) {
                state = SaleState.PublicSaleFinalized;
            }
        }
    }

     
    function calculateValueFromTokens (uint256 _tokens) internal returns (uint256) {
        uint256 amount = _tokens.div(ethRate.div(partnerSaleTokenPrice));
        return amount;
    }

     
    function distributeFoundingTeamTokens (address[] _recipients) private returns (bool) {
         
         
         
         
        uint percentage = foundersPercentOfTotal / _recipients.length;

        for (uint i = 0; i < _recipients.length; i++) {
            distribute(_recipients[i], percentage);
        }
    }

     
    function distribute (address _recipient, uint percentage) private returns (bool) {
        uint256 tokens = totalSupply / (hundredPercent / percentage);

        balances[owner] = balances[owner].sub(tokens);
        balances[_recipient] = balances[_recipient].add(tokens);
        Transfer(0, _recipient, tokens);
    }

     
    function isStatePartnerSale () private constant returns (bool) {
        return state == SaleState.PartnerSale;
    }

     
    function isStatePreSale () private constant returns (bool) {
        return state == SaleState.PreSale;
    }

     
    function isStatePublicSale () private constant returns (bool) {
        return state == SaleState.PublicSale;
    }
}