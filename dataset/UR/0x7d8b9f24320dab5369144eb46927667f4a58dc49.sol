 

pragma solidity ^ 0.4.18;

 
contract Owned {
    address public owner;
   
     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract TokenERC20 is Pausable {
    using SafeMath for uint256;
     
    string public name = "NRC";
    string public symbol = "R";
    uint8 public decimals = 0;
     
    uint256 public rate = 50000;
     
    address public wallet = 0xd3C8326064044c36B73043b009155a59e92477D0;
     
    address public contributorsAddress = 0xa7db53CB73DBe640DbD480a928dD06f03E2aE7Bd;
     
    address public companyAddress = 0x9c949b51f2CafC3A5efc427621295489B63D861D;
     
    address public marketAddress = 0x199EcdFaC25567eb4D21C995B817230050d458d9;
     
    uint8 public constant ICO_SHARE = 20;
    uint8 public constant CONTRIBUTORS_SHARE = 30;
    uint8 public constant COMPANY_SHARE = 20;
    uint8 public constant MARKET_SHARE = 30;
     
    uint8 constant COMPANY_PERIODS = 10;
    uint8 constant CONTRIBUTORS_PERIODS = 3;
     
    uint256 public constant TOTAL_SUPPLY = 80000000000;
     
    uint256 public icoTotalAmount = 16000000000;
    uint256 public companyPeriodsElapsed;
    uint256 public contributorsPeriodsElapsed;
     
    uint256 public frozenSupply;
    uint256 public initDate;
    uint8 public contributorsCurrentPeriod;
    uint8 public companyCurrentPeriod;
     
    mapping(address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event InitialToken(string desc, address indexed target, uint256 value);    
    
     
    function TokenERC20(
    ) public {
         
        uint256 tempContributors = TOTAL_SUPPLY.mul(CONTRIBUTORS_SHARE).div(100).div(CONTRIBUTORS_PERIODS);
        contributorsPeriodsElapsed = tempContributors;
        balanceOf[contributorsAddress] = tempContributors;
        InitialToken("contributors", contributorsAddress, tempContributors);
        
         
        uint256 tempCompany = TOTAL_SUPPLY.mul(COMPANY_SHARE).div(100).div(COMPANY_PERIODS);
        companyPeriodsElapsed = tempCompany;
        balanceOf[companyAddress] = tempCompany;
        InitialToken("company", companyAddress, tempCompany);

         
        uint256 tempIco = TOTAL_SUPPLY.mul(ICO_SHARE).div(100);
        icoTotalAmount = tempIco;

         
        uint256 tempMarket = TOTAL_SUPPLY.mul(MARKET_SHARE).div(100);
        balanceOf[marketAddress] = tempMarket;
        InitialToken("market", marketAddress, tempMarket);

         
        uint256 tempFrozenSupply = TOTAL_SUPPLY.sub(tempContributors).sub(tempIco).sub(tempCompany).sub(tempMarket);
        frozenSupply = tempFrozenSupply;
        initDate = block.timestamp;
        contributorsCurrentPeriod = 1;
        companyCurrentPeriod = 1;
        paused = true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
}
 
 
 

contract NRCToken is Owned, TokenERC20 {
    uint256 private etherChangeRate = 10 ** 18;
    uint256 private minutesOneYear = 365*24*60 minutes;
    bool public  tokenSaleActive = true;
     
    uint256 public totalSoldToken;
     
    mapping(address => bool) public frozenAccount;

     
    event LogFrozenAccount(address target, bool frozen);
    event LogUnfrozenTokens(string desc, address indexed targetaddress, uint256 unfrozenTokensAmount);
    event LogSetTokenPrice(uint256 tokenPrice);
    event TimePassBy(string desc, uint256 times );
     
    event LogTokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
     
    event TokenSaleFinished(string desc, address indexed contributors, uint256 icoTotalAmount, uint256 totalSoldToken, uint256 leftAmount);
    
     
    function NRCToken() TokenERC20() public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_from != _to);
        require(_to != 0x0);  
        require(balanceOf[_from] >= _value);  
        require(balanceOf[_to].add(_value) > balanceOf[_to]);  
        require(!frozenAccount[_from]);  
        require(!frozenAccount[_to]);  
        balanceOf[_from] = balanceOf[_from].sub(_value);  
        balanceOf[_to] = balanceOf[_to].add(_value);  
        Transfer(_from, _to, _value);
    }
        
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
    function freezeAccount(address target, bool freeze) public onlyOwner whenNotPaused {
        require(target != 0x0);
        require(target != owner);
        require(frozenAccount[target] != freeze);
        frozenAccount[target] = freeze;
        LogFrozenAccount(target, freeze);
    }

     
     
    function setPrices(uint256 newTokenRate) public onlyOwner whenNotPaused {
        require(newTokenRate > 0);
        require(newTokenRate <= icoTotalAmount);
        require(tokenSaleActive);
        rate = newTokenRate;
        LogSetTokenPrice(newTokenRate);
    }

     
    function buy() public payable whenNotPaused {
         
        require(!frozenAccount[msg.sender]); 
        require(tokenSaleActive);
        require(validPurchase());
        uint tokens = getTokenAmount(msg.value);  
        require(!validSoldOut(tokens));
        LogTokenPurchase(msg.sender, msg.value, tokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        calcTotalSoldToken(tokens);
        forwardFunds();
    }

     
    function getTokenAmount(uint256 etherAmount) internal view returns(uint256) {
        uint256 temp = etherAmount.mul(rate);
        uint256 amount = temp.div(etherChangeRate);
        return amount;
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function calcTotalSoldToken(uint256 soldAmount) internal {
        totalSoldToken = totalSoldToken.add(soldAmount);
        if (totalSoldToken >= icoTotalAmount) { 
            tokenSaleActive = false;
        }
    }

     
    function validPurchase() internal view returns(bool) {
        bool limitPurchase = msg.value >= 1 ether;
        bool isNotTheOwner = msg.sender != owner;
        bool isNotTheCompany = msg.sender != companyAddress;
        bool isNotWallet = msg.sender != wallet;
        bool isNotContributors = msg.sender != contributorsAddress;
        bool isNotMarket = msg.sender != marketAddress;
        return limitPurchase && isNotTheOwner && isNotTheCompany && isNotWallet && isNotContributors && isNotMarket;
    }

     
    function validSoldOut(uint256 soldAmount) internal view returns(bool) {
        return totalSoldToken.add(soldAmount) > icoTotalAmount;
    }
     
    function time() internal constant returns (uint) {
        return block.timestamp;
    }

     
     
    function finaliseICO() public onlyOwner whenNotPaused {
        require(tokenSaleActive == true);        
        uint256 tokensLeft = icoTotalAmount.sub(totalSoldToken);
        tokenSaleActive = false;
        require(tokensLeft > 0);
        balanceOf[contributorsAddress] = balanceOf[contributorsAddress].add(tokensLeft);
        TokenSaleFinished("finaliseICO", contributorsAddress, icoTotalAmount, totalSoldToken, tokensLeft);
        totalSoldToken = icoTotalAmount;
    }


     
    function unfrozenTokens() public onlyOwner whenNotPaused {
        require(frozenSupply >= 0);
        if (contributorsCurrentPeriod < CONTRIBUTORS_PERIODS) {
            unfrozenContributorsTokens();
            unfrozenCompanyTokens();
        } else {
            unfrozenCompanyTokens();
        }
    }

     
    function unfrozenContributorsTokens() internal {
        require(contributorsCurrentPeriod < CONTRIBUTORS_PERIODS);
        uint256 contributortimeShouldPassBy = contributorsCurrentPeriod * (minutesOneYear);
        TimePassBy("contributortimeShouldPassBy", contributortimeShouldPassBy);
        uint256 contributorsTimePassBy = time() - initDate;
        TimePassBy("contributortimePassBy", contributorsTimePassBy);

        contributorsCurrentPeriod = contributorsCurrentPeriod + 1;
        require(contributorsTimePassBy >= contributortimeShouldPassBy);
        frozenSupply = frozenSupply.sub(contributorsPeriodsElapsed);
        balanceOf[contributorsAddress] = balanceOf[contributorsAddress].add(contributorsPeriodsElapsed);
        LogUnfrozenTokens("contributors", contributorsAddress, contributorsPeriodsElapsed);
    }

     
    function unfrozenCompanyTokens() internal {
        require(companyCurrentPeriod < COMPANY_PERIODS);
        uint256 companytimeShouldPassBy = companyCurrentPeriod * (minutesOneYear);
        TimePassBy("CompanytimeShouldPassBy", companytimeShouldPassBy);
        uint256 companytimePassBy = time() - initDate;
        TimePassBy("CompanytimePassBy", companytimePassBy);

        require(companytimePassBy >= companytimeShouldPassBy);
        companyCurrentPeriod = companyCurrentPeriod + 1;
        frozenSupply = frozenSupply.sub(companyPeriodsElapsed);
        balanceOf[companyAddress] = balanceOf[companyAddress].add(companyPeriodsElapsed);
        LogUnfrozenTokens("company", companyAddress, companyPeriodsElapsed);
    }

     
    function() external {
        revert();
    }

}