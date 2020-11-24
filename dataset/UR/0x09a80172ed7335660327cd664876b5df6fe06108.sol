 

pragma solidity ^0.4.13;

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

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Discountable is Ownable {
    struct DiscStruct {
        uint256 amount;
        uint256 disc;
    }
    uint256 descPrecision = 1e2;
    uint256 defaultCoef = 200;
    DiscStruct[] public discounts;

    function addDiscount(uint256 _amount, uint256 _disc) onlyOwner public{
        discounts.push(DiscStruct(_amount, _disc));
    }

    function editDiscount(uint256 num, uint256 _amount, uint256 _disc) onlyOwner public{
        discounts[num] = DiscStruct(_amount, _disc);
    }

    function getDiscountsAmount() public view returns(uint256 amount_){
        return discounts.length;
    }

    function getDiscountByAmount(uint256 amount) internal view returns(uint256 disc_){
        uint256 arrayLength = discounts.length;
        if (amount < discounts[0].amount){
            return defaultCoef;
        }
        for (uint8 i=0; i<arrayLength; i++) {
            if(i == arrayLength - 1){
                return discounts[arrayLength - 1].disc;
            }
            if (amount < discounts[i+1].amount){
                return discounts[i].disc;
            }
        }
        return defaultCoef;
    }

}

contract TransferStatistics {
    using SafeMath for uint256;

    uint256 private stat_tokensBoughtBack = 0;
    uint256 private stat_timesBoughtBack = 0;
    uint256 private stat_tokensPurchased = 0;
    uint256 private stat_timesPurchased = 0;

    uint256 private stat_ethSent = 0;
    uint256 private stat_ethReceived = 0;

    uint256 private stat_tokensSpend = 0;
    uint256 private stat_timesSpend = 0;

    uint256 private oddSent = 0;
    uint256 private feeSent = 0;

    function trackPurchase(uint256 tokens, uint256 sum) internal {
        stat_tokensPurchased = stat_tokensPurchased.add(tokens);
        stat_timesPurchased = stat_timesPurchased.add(1);
        stat_ethSent = stat_ethSent.add(sum);
    }

    function trackBuyBack(uint256 tokens, uint256 sum) internal {
        stat_tokensBoughtBack = stat_tokensBoughtBack.add(tokens);
        stat_timesBoughtBack = stat_timesBoughtBack.add(1);
        stat_ethReceived = stat_ethReceived.add(sum);
    }

    function trackSpend(uint256 tokens) internal{
        stat_tokensSpend = stat_tokensSpend.add(tokens);
        stat_timesSpend = stat_timesSpend.add(1);
    }

    function trackOdd(uint256 odd) internal {
        oddSent = oddSent.add(odd);
    }

    function trackFee(uint256 fee) internal {
        feeSent = feeSent.add(fee);
    }

    function getStatistics() internal view returns(
        uint256 tokensBoughtBack_, uint256 timesBoughtBack_,
        uint256 tokensPurchased_, uint256 timesPurchased_,
        uint256 ethSent_, uint256 ethReceived_,
        uint256 tokensSpend_, uint256 timesSpend_,
        uint256 oddSent_, uint256 feeSent_) {
        return (stat_tokensBoughtBack, stat_timesBoughtBack,
        stat_tokensPurchased, stat_timesPurchased,
        stat_ethSent, stat_ethReceived,
        stat_tokensSpend, stat_timesSpend,
        oddSent, feeSent);
    }
}

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }


    modifier onlyInEmergency {
        require(halted);
        _;
    }


     
    function halt() external onlyOwner {
        halted = true;
    }


     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public onlyOwner{
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OMPxContract is BasicToken, Haltable, Discountable, TransferStatistics {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    using SafeERC20 for OMPxToken;
     
    OMPxToken public token;
    Distribution public feeReceiverContract;    
    uint256 private feeBalance = 0;

    event TransferMoneyBack(address indexed to, uint256 value);
    event Donation(address indexed donator, uint256 value);
    event Spend(address indexed spender, uint256 tokensAmount, bytes32 indexed orderId);
    event Purchase(address indexed received, uint256 tokensAmount, uint256 value);
    event BuyBack(address indexed received, uint256 tokensAmount, uint256 value);
    event NewReceiverSet(address newReceiver);

    function OMPxContract() public payable{
        addDiscount(1000 * 1e18,198);
        addDiscount(5000 * 1e18,190);
        addDiscount(20000 * 1e18,180);
        addDiscount(100000 * 1e18,150);

        token = new OMPxToken();
        token.mint(owner, token.initialSupply());
    }

     

    function() public payable {
        emit Donation(msg.sender, msg.value);
    }

    function setFeeReceiver(address newReceiver) public onlyOwner {
        require(newReceiver != address(0));
        feeReceiverContract = Distribution(newReceiver);
        emit NewReceiverSet(newReceiver);
    }

    function getFee() public {
        if(feeBalance > 1e15){
            feeReceiverContract.receiveFunds.value(feeBalance).gas(150000)();
            trackFee(feeBalance);
            feeBalance = 0;
        }
    }

    function totalTokenSupply() public view returns(uint256 totalSupply_) {
        return token.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance_) {
        return token.balanceOf(_owner);
    }

     
    function getBuyBackPrice(uint256 buyBackValue) public view returns(uint256 price_) {
        if (address(this).balance==0) {
            return 0;
        }
        uint256 eth;
        uint256 tokens = token.totalSupply();
        if (buyBackValue > 0) {
            eth = address(this).balance.sub(buyBackValue);
        } else {
            eth = address(this).balance;
        }
        return (eth.sub(feeBalance)).mul(1e18).div(tokens);
    }


    function getPurchasePrice(uint256 purchaseValue, uint256 amount) public view returns(uint256 price_) {
        require(purchaseValue >= 0);
        require(amount >= 0);
        uint256 buyerContributionCoefficient = getDiscountByAmount(amount);
        uint256 price = getBuyBackPrice(purchaseValue).mul(buyerContributionCoefficient).div(descPrecision);
        if (price <= 0) {price = 1e11;}
        return price;
    }


     
     
    function purchase(uint256 tokensToPurchase, uint256 maxPrice) public payable returns(uint256 tokensBought_) {
        require(tokensToPurchase > 0);
        require(msg.value > 0);
        return purchaseSafe(tokensToPurchase, maxPrice);
    }

    function purchaseSafe(uint256 tokensToPurchase, uint256 maxPrice) internal returns(uint256 tokensBought_){
        require(maxPrice >= 0);

        uint256 currentPrice = getPurchasePrice(msg.value, tokensToPurchase);
        require(currentPrice <= maxPrice);

        uint256 tokensWuiAvailableByCurrentPrice = msg.value.mul(1e18).div(currentPrice);
        if(tokensWuiAvailableByCurrentPrice > tokensToPurchase) {
            tokensWuiAvailableByCurrentPrice = tokensToPurchase;
        }
        uint256 totalDealPrice = currentPrice.mul(tokensWuiAvailableByCurrentPrice).div(1e18);
        require(msg.value >= tokensToPurchase.mul(maxPrice).div(1e18));
        require(msg.value >= totalDealPrice);

         
        feeBalance = feeBalance + totalDealPrice.div(9);

         
        uint256 availableTokens = token.balanceOf(this);
        if (availableTokens < tokensWuiAvailableByCurrentPrice) {
            uint256 tokensToMint = tokensWuiAvailableByCurrentPrice.sub(availableTokens);
            token.mint(this, tokensToMint);
        }
        token.safeTransfer(msg.sender, tokensWuiAvailableByCurrentPrice);

         
        if (totalDealPrice < msg.value) {
             
            uint256 oddEthers = msg.value.sub(totalDealPrice);
            if (oddEthers > 0) {
                require(oddEthers < msg.value);
                emit TransferMoneyBack(msg.sender, oddEthers);
                msg.sender.transfer(oddEthers);
                trackOdd(oddEthers);
            }
        }
        emit Purchase(msg.sender, tokensToPurchase, totalDealPrice);
        trackPurchase(tokensWuiAvailableByCurrentPrice, totalDealPrice);
        return tokensWuiAvailableByCurrentPrice;
    }

     
    function buyBack(uint256 tokensToBuyBack, uint256 minPrice) public {
        uint currentPrice = getBuyBackPrice(0);
        require(currentPrice >= minPrice);
        uint256 totalPrice = tokensToBuyBack.mul(currentPrice).div(1e18);
        require(tokensToBuyBack > 0);
        require(tokensToBuyBack <= token.balanceOf(msg.sender));

        token.safeTransferFrom(msg.sender, this, tokensToBuyBack);

        emit BuyBack(msg.sender, tokensToBuyBack, totalPrice);
        trackBuyBack(tokensToBuyBack, totalPrice);
         
        msg.sender.transfer(totalPrice);
    }

     
    function spend(uint256 tokensToSpend, bytes32 orderId) public {
        token.safeTransferFrom(msg.sender, this, tokensToSpend);
        token.burn(tokensToSpend);
        trackSpend(tokensToSpend);
        emit Spend(msg.sender, tokensToSpend, orderId);
    }

     
    function purchaseUpAndSpend(uint256 tokensToSpend, uint256 maxPrice, bytes32 orderId) public payable returns(uint256 tokensSpent_){
        uint256 tokensToPurchaseUp = tokensToSpend.sub(token.balanceOf(msg.sender));
        uint256 currentPrice = getPurchasePrice(msg.value, tokensToPurchaseUp);
        uint256 tokensAvailableByCurrentPrice = msg.value.mul(1e18).div(currentPrice);
        require(tokensToPurchaseUp <= tokensAvailableByCurrentPrice);

        if (tokensToPurchaseUp>0) {
            purchase(tokensToPurchaseUp, maxPrice);
        }
        spend(tokensToSpend, orderId);
        return tokensToSpend;
    }

    function getStat() onlyOwner public view returns(
        uint256 tokensBoughtBack_, uint256 timesBoughtBack_,
        uint256 tokensPurchased_, uint256 timesPurchased_,
        uint256 ethSent_, uint256 ethReceived_,
        uint256 tokensSpend_, uint256 timesSpend_,
        uint256 oddSent_, uint256 feeSent_) {
        return getStatistics();
    }
}

contract Distribution is Ownable {
    using SafeMath for uint256;

    struct Recipient {
        address addr;
        uint256 share;
        uint256 balance;
        uint256 received;
    }

    uint256 sharesSum;
    uint8 constant maxRecsAmount = 12;
    mapping(address => Recipient) public recs;
    address[maxRecsAmount] public recsLookUpTable;  

    event Payment(address indexed to, uint256 value);
    event AddShare(address to, uint256 value);
    event ChangeShare(address to, uint256 value);
    event DeleteShare(address to);
    event ChangeAddessShare(address newAddress);
    event FoundsReceived(uint256 value);

    function Distribution() public {
        sharesSum = 0;
    }

    function receiveFunds() public payable {
        emit FoundsReceived(msg.value);
        for (uint8 i = 0; i < maxRecsAmount; i++) {
            Recipient storage rec = recs[recsLookUpTable[i]];
            uint ethAmount = (rec.share.mul(msg.value)).div(sharesSum);
            rec.balance = rec.balance + ethAmount;
        }
    }

    modifier onlyMembers(){
        require(recs[msg.sender].addr != address(0));
        _;
    }

    function doPayments() public {
        Recipient storage rec = recs[msg.sender];
        require(rec.balance >= 1e12);
        rec.addr.transfer(rec.balance);
        emit Payment(rec.addr, rec.balance);
        rec.received = (rec.received).add(rec.balance);
        rec.balance = 0;
    }

    function addShare(address _rec, uint256 share) public onlyOwner {
        require(_rec != address(0));
        require(share > 0);
        require(recs[_rec].addr == address(0));
        recs[_rec].addr = _rec;
        recs[_rec].share = share;
        recs[_rec].received = 0;
        for(uint8 i = 0; i < maxRecsAmount; i++ ) {
            if (recsLookUpTable[i] == address(0)) {
                recsLookUpTable[i] = _rec;
                break;
            }
        }
        sharesSum = sharesSum.add(share);
        emit AddShare(_rec, share);
    }

    function changeShare(address _rec, uint share) public onlyOwner {
        require(_rec != address(0));
        require(share > 0);
        require(recs[_rec].addr != address(0));
        Recipient storage rec = recs[_rec];
        sharesSum = sharesSum.sub(rec.share).add(share);
        rec.share = share;
        emit ChangeShare(_rec, share);
    }

    function deleteShare(address _rec) public onlyOwner {
        require(_rec != address(0));
        require(recs[_rec].addr != address(0));
        sharesSum = sharesSum.sub(recs[_rec].share);
        for(uint8 i = 0; i < maxRecsAmount; i++ ) {
            if (recsLookUpTable[i] == recs[_rec].addr) {
                recsLookUpTable[i] = address(0);
                break;
            }
        }
        delete recs[_rec];
        emit DeleteShare(msg.sender);
    }

    function changeRecipientAddress(address _newRec) public {
        require(msg.sender != address(0));
        require(_newRec != address(0));
        require(recs[msg.sender].addr != address(0));
        require(recs[_newRec].addr == address(0));
        require(recs[msg.sender].addr != _newRec);

        Recipient storage rec = recs[msg.sender];
        uint256 prevBalance = rec.balance;
        addShare(_newRec, rec.share);
        emit ChangeAddessShare(_newRec);
        deleteShare(msg.sender);
        recs[_newRec].balance = prevBalance;
        emit DeleteShare(msg.sender);

    }

    function getMyBalance() public view returns(uint256) {
        return recs[msg.sender].balance;
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;
  address internal owner;

  function StandardToken() public {
     
    owner = msg.sender;
  }
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender] || msg.sender == owner);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (msg.sender != owner) {
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract OMPxToken is BurnableToken, MintableToken{
    using SafeMath for uint256;
    uint32 public constant decimals = 18;
    uint256 public constant initialSupply = 1e24;

    string public constant name = "OMPx Token";
    string public constant symbol = "OMPX";
}