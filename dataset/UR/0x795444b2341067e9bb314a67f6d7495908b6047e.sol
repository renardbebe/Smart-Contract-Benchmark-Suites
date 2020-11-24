 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

      
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

      
    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
  }

}

 
 library SafeMath {
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a * b;
         assert(a == 0 || c / a == b);
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

     function max64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a >= b ? a : b;
     }

     function min64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a < b ? a : b;
     }

     function max256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a >= b ? a : b;
     }

     function min256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a < b ? a : b;
     }
 }

 
 contract ERC20Basic {
     uint256 public totalSupply;

     function balanceOf(address who) public view returns (uint256);
     function transfer(address to, uint256 value) public returns (bool);

     event Transfer(address indexed from, address indexed to, uint256 value);
 }

 
 contract ERC20 {
     uint256 public totalSupply;

     function balanceOf(address _owner) public constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     function approve(address _spender, uint256 _value) public returns (bool success);
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 contract BasicToken is ERC20Basic {
     using SafeMath for uint256;

     mapping (address => uint256) balances;

      
     uint256 public presaleStartTime = 1537736400;

      
     uint256 public presaleEndTime = 1540414799;

      
     uint256 public mainsaleStartTime = 1541278800;

      
     uint256 public mainsaleEndTime = 1546635599;

     address public constant investor1 = 0x8013e8F85C9bE7baA19B9Fd9a5Bc5C6C8D617446;
     address public constant investor2 = 0xf034E5dB3ed5Cb26282d2DC5802B21DB3205B882;
     address public constant investor3 = 0x1A7dD28A461D7e0D75b89b214d5188E0304E5726;

      
     function transfer(address _to, uint256 _value) public returns (bool) {
         require(_to != address(0));
         require(_value <= balances[msg.sender]);
         if (( (msg.sender == investor1) || (msg.sender == investor2) || (msg.sender == investor3)) && (now < (presaleStartTime + 300 days))) {
           revert();
         }
          
         balances[msg.sender] = balances[msg.sender].sub(_value);
         balances[_to] = balances[_to].add(_value);
         emit Transfer(msg.sender, _to, _value);
         return true;
     }

      
     function balanceOf(address _owner) public constant returns (uint256 balance) {
         return balances[_owner];
     }

 }

 
 contract StandardToken is ERC20, BasicToken {

     mapping (address => mapping (address => uint256)) internal allowed;

      
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
         require(_to != address(0));
         require(_value <= balances[_from]);
         require(_value <= allowed[_from][msg.sender]);
         if (( (_from == investor1) || (_from == investor2) || (_from == investor3)) && (now < (presaleStartTime + 300 days))) {
           revert();
         }

         balances[_from] = balances[_from].sub(_value);
         balances[_to] = balances[_to].add(_value);
         allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
         emit Transfer(_from, _to, _value);
         return true;
     }

      
     function approve(address _spender, uint256 _value) public returns (bool) {
         allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
         return true;
     }

      
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }

      
     function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
         allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

     function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
         uint oldValue = allowed[msg.sender][_spender];
         if (_subtractedValue > oldValue) {
             allowed[msg.sender][_spender] = 0;
         }
         else {
             allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
         }
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

 }

 

contract MintableToken is StandardToken, Ownable {
    string public constant name = "Kartblock";
    string public constant symbol = "KBT";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract Whitelist is Ownable {

    mapping (address => bool) verifiedAddresses;

    function isAddressWhitelist(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }

    function whitelistAddress(address _newAddress) external onlyOwner {
        verifiedAddresses[_newAddress] = true;
    }

    function removeWhitelistAddress(address _oldAddress) external onlyOwner {
        require(verifiedAddresses[_oldAddress]);
        verifiedAddresses[_oldAddress] = false;
    }

    function batchWhitelistAddresses(address[] _addresses) external onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
    }
}

 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
     
    address public wallet;

     
    uint256 public PresaleWeiRaised;
    uint256 public mainsaleWeiRaised;
    uint256 public tokenAllocated;

    event WalletChanged(address indexed previousWallet, address indexed newWallet);

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function transferWallet(address newWallet) public onlyOwner {
      _transferOwnership(newWallet);
    }

    function _transferWallet(address newWallet) internal {
      require(newWallet != address(0));
      emit WalletChanged(owner, newWallet);
      wallet = newWallet;
    }
}

contract KartblockCrowdsale is Ownable, Crowdsale, Whitelist, MintableToken {
    using SafeMath for uint256;


     
    uint256 public constant presaleCap = 10000 * (10 ** uint256(decimals));
    uint256 public constant mainsaleCap = 175375 * (10 ** uint256(decimals));
    uint256 public constant mainsaleGoal = 11700 * (10 ** uint256(decimals));

     
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant totalTokensForSale = 195500000 * (10 ** uint256(decimals));
    uint256 public constant tokensForFuture = 760000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForswap = 4500000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester1 = 16000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester2 = 16000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester3 = 8000000 * (10 ** uint256(decimals));

     
    uint256 public rate;
    mapping (address => uint256) public deposited;
    address[] investors;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Finalized();

    constructor(
      address _owner,
      address _wallet
      ) public Crowdsale(_wallet) {

        require(_wallet != address(0));
        require(_owner != address(0));
        owner = _owner;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        rate = 1140;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
        balances[0x9AF6043d1B74a7c9EC7e3805Bc10e41230537A8B] = balances[0x9AF6043d1B74a7c9EC7e3805Bc10e41230537A8B].add(tokensForswap);
        mainsaleWeiRaised.add(tokensForswap);
        balances[investor1] = balances[investor1].add(tokensForInvester1);
        balances[investor2] = balances[investor1].add(tokensForInvester2);
        balances[investor3] = balances[investor1].add(tokensForInvester3);
    }

     
    function() payable public {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _investor) public  payable returns (uint256){
        require(_investor != address(0));
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        if (tokens == 0) {revert();}

         
        if (isPresalePeriod())  {
          PresaleWeiRaised = PresaleWeiRaised.add(weiAmount);
        } else if (isMainsalePeriod()) {
          mainsaleWeiRaised = mainsaleWeiRaised.add(weiAmount);
        }
        tokenAllocated = tokenAllocated.add(tokens);
        if (verifiedAddresses[_investor]) {
           mint(_investor, tokens, owner);
        }else {
          investors.push(_investor);
          deposited[_investor] = deposited[_investor].add(tokens);
        }
        emit TokenPurchase(_investor, weiAmount, tokens);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
      return _weiAmount.mul(rate);
    }

     
    function setPrice() public onlyOwner {
      if (isPresalePeriod()) {
        rate = 1140;
      } else if (isMainsalePeriod()) {
        rate = 1597;
      }
    }

    function isPresalePeriod() public view returns (bool) {
      if (now >= presaleStartTime && now < presaleEndTime) {
        return true;
      }
      return false;
    }

    function isMainsalePeriod() public view returns (bool) {
      if (now >= mainsaleStartTime && now < mainsaleEndTime) {
        return true;
      }
      return false;
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

     
    function validPurchase() internal view returns (bool) {
      bool withinCap =  true;
      if (isPresalePeriod()) {
        withinCap = PresaleWeiRaised.add(msg.value) <= presaleCap;
      } else if (isMainsalePeriod()) {
        withinCap = mainsaleWeiRaised.add(msg.value) <= mainsaleCap;
      }
      bool withinPeriod = isPresalePeriod() || isMainsalePeriod();
      bool minimumContribution = msg.value >= 0.5 ether;
      return withinPeriod && minimumContribution && withinCap;
    }

    function readyForFinish() internal view returns(bool) {
      bool endPeriod = now < mainsaleEndTime;
      bool reachCap = tokenAllocated <= mainsaleCap;
      return endPeriod || reachCap;
    }


     
    function finalize(
      address _tokensForFuture
      ) public onlyOwner returns (bool result) {
        require(_tokensForFuture != address(0));
        require(readyForFinish());
        result = false;
        mint(_tokensForFuture, tokensForFuture, owner);
        address contractBalance = this;
        wallet.transfer(contractBalance.balance);
        finishMinting();
        emit Finalized();
        result = true;
    }

    function transferToInvester() public onlyOwner returns (bool result) {
        require( now >= 1548363600);
        for (uint cnt = 0; cnt < investors.length; cnt++) {
            mint(investors[cnt], deposited[investors[cnt]], owner);
        }
        result = true;
    }

}