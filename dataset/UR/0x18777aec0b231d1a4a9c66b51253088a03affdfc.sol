 

pragma solidity ^0.4.21;

contract LuckchemyCrowdsale {
    using SafeMath for uint256;

     
    LuckchemyToken public token;

     

     
    uint256 public constant START_TIME_SALE = 1525046400;

     
    uint256 public constant END_TIME_SALE = 1532131199;

     
    uint256 public constant START_TIME_PRESALE = 1522627200;

     
    uint256 public constant END_TIME_PRESALE = 1524614399;


     
    uint256 public tokensSold = 0;

     
    uint256 public totalSupply = 0;
     
    uint256 public constant hardCap = 45360 ether;
     
    uint256 public constant softCap = 2000 ether;

     
    uint256 public fiatBalance = 0;
     
    uint256 public ethBalance = 0;

     
    address public serviceAgent;

     
    address public owner;

     
    uint256 public constant RATE = 12500;  

     
    uint256 public constant DISCOUNT_PRIVATE_PRESALE = 80;  

     
    uint256 public constant DISCOUNT_STAGE_ONE = 40;   

     
    uint256 public constant DISCOUNT_STAGE_TWO = 20;  

     
    uint256 public constant DISCOUNT_STAGE_THREE = 0;




     
    mapping(address => bool) public whitelist;


     
    uint256 public constant LOTTERY_FUND_SHARE = 40;
    uint256 public constant OPERATIONS_SHARE = 50;
    uint256 public constant PARTNERS_SHARE = 10;

    address public constant LOTTERY_FUND_ADDRESS = 0x84137CB59076a61F3f94B2C39Da8fbCb63B6f096;
    address public constant OPERATIONS_ADDRESS = 0xEBBeAA0699837De527B29A03ECC914159D939Eea;
    address public constant PARTNERS_ADDRESS = 0x820502e8c80352f6e11Ce036DF03ceeEBE002642;

     
    event TokenETHPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


     
    event TokenFiatPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
     
    modifier onlyServiceAgent(){
        require(msg.sender == serviceAgent);
        _;
    }

     
    modifier onlyWhiteList(address _address){
        require(whitelist[_address] == true);
        _;
    }
     

    enum Stage {
        Private,
        Discount40,
        Discount20,
        NoDiscount
    }

     
    Stage public  currentStage;

     
    mapping(uint256 => uint256) public tokenPools;

     
    mapping(uint256 => uint256) public stageRates;

     
    mapping(address => uint256) public deposits;

     
    function LuckchemyCrowdsale(address _service) public {
        require(START_TIME_SALE >= now);
        require(START_TIME_SALE > END_TIME_PRESALE);
        require(END_TIME_SALE > START_TIME_SALE);

        require(_service != 0x0);

        owner = msg.sender;
        serviceAgent = _service;
        token = new LuckchemyToken();
        totalSupply = token.CROWDSALE_SUPPLY();

        currentStage = Stage.Private;

        uint256 decimals = uint256(token.decimals());

        tokenPools[uint256(Stage.Private)] = 70000000 * (10 ** decimals);
        tokenPools[uint256(Stage.Discount40)] = 105000000 * (10 ** decimals);
        tokenPools[uint256(Stage.Discount20)] = 175000000 * (10 ** decimals);
        tokenPools[uint256(Stage.NoDiscount)] = 350000000 * (10 ** decimals);

        stageRates[uint256(Stage.Private)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_PRIVATE_PRESALE);
        stageRates[uint256(Stage.Discount40)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_ONE);
        stageRates[uint256(Stage.Discount20)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_TWO);
        stageRates[uint256(Stage.NoDiscount)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_THREE);

    }

     
    function depositOf(address depositor) public constant returns (uint256) {
        return deposits[depositor];
    }
     
    function() public payable {
        payETH(msg.sender);
    }


     
    function payETH(address beneficiary) public onlyWhiteList(beneficiary) payable {

        require(msg.value >= 0.1 ether);
        require(beneficiary != 0x0);
        require(validPurchase());
        if (isPrivateSale()) {
            processPrivatePurchase(msg.value, beneficiary);
        } else {
            processPublicPurchase(msg.value, beneficiary);
        }


    }

     
    function processPrivatePurchase(uint256 weiAmount, address beneficiary) private {

        uint256 stage = uint256(Stage.Private);

        require(currentStage == Stage.Private);
        require(tokenPools[stage] > 0);

         
        uint256 tokensToBuy = (weiAmount.mul(stageRates[stage])).div(1 ether);
        if (tokensToBuy <= tokenPools[stage]) {
             
            payoutTokens(beneficiary, tokensToBuy, weiAmount);

        } else {
             
            tokensToBuy = tokenPools[stage];
             
            uint256 usedWei = (tokensToBuy.mul(1 ether)).div(stageRates[stage]);
            uint256 leftWei = weiAmount.sub(usedWei);

            payoutTokens(beneficiary, tokensToBuy, usedWei);

             
            currentStage = Stage.Discount40;

             
            beneficiary.transfer(leftWei);
        }
    }
     
    function processPublicPurchase(uint256 weiAmount, address beneficiary) private {

        if (currentStage == Stage.Private) {
            currentStage = Stage.Discount40;
            tokenPools[uint256(Stage.Discount40)] = tokenPools[uint256(Stage.Discount40)].add(tokenPools[uint256(Stage.Private)]);
            tokenPools[uint256(Stage.Private)] = 0;
        }

        for (uint256 stage = uint256(currentStage); stage <= 3; stage++) {

             
            uint256 tokensToBuy = (weiAmount.mul(stageRates[stage])).div(1 ether);

            if (tokensToBuy <= tokenPools[stage]) {
                 
                payoutTokens(beneficiary, tokensToBuy, weiAmount);

                break;
            } else {
                 
                tokensToBuy = tokenPools[stage];
                 
                uint256 usedWei = (tokensToBuy.mul(1 ether)).div(stageRates[stage]);
                uint256 leftWei = weiAmount.sub(usedWei);

                payoutTokens(beneficiary, tokensToBuy, usedWei);

                if (stage == 3) {
                     
                    beneficiary.transfer(leftWei);
                    break;
                } else {
                    weiAmount = leftWei;
                     
                    currentStage = Stage(stage + 1);
                }
            }
        }
    }
     
    function payoutTokens(address beneficiary, uint256 tokenAmount, uint256 weiAmount) private {
        uint256 stage = uint256(currentStage);
        tokensSold = tokensSold.add(tokenAmount);
        tokenPools[stage] = tokenPools[stage].sub(tokenAmount);
        deposits[beneficiary] = deposits[beneficiary].add(weiAmount);
        ethBalance = ethBalance.add(weiAmount);

        token.transfer(beneficiary, tokenAmount);
        TokenETHPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }
     
    function setServiceAgent(address _newServiceAgent) public onlyOwner {
        serviceAgent = _newServiceAgent;
    }
     
    function payFiat(address beneficiary, uint256 amount, uint256 stage) public onlyServiceAgent onlyWhiteList(beneficiary) {

        require(beneficiary != 0x0);
        require(tokenPools[stage] >= amount);
        require(stage == uint256(currentStage));

         
        uint256 fiatWei = amount.mul(1 ether).div(stageRates[stage]);
        fiatBalance = fiatBalance.add(fiatWei);
        require(validPurchase());

        tokenPools[stage] = tokenPools[stage].sub(amount);
        tokensSold = tokensSold.add(amount);

        token.transfer(beneficiary, amount);
        TokenFiatPurchase(msg.sender, beneficiary, amount);
    }


     
    function hasEnded() public constant returns (bool) {
        return now > END_TIME_SALE || tokensSold >= totalSupply;
    }

     
    function hardCapReached() public constant returns (bool) {
        return tokensSold >= totalSupply || fiatBalance.add(ethBalance) >= hardCap;
    }
     
    function softCapReached() public constant returns (bool) {
        return fiatBalance.add(ethBalance) >= softCap;
    }

    function isPrivateSale() public constant returns (bool) {
        return now >= START_TIME_PRESALE && now <= END_TIME_PRESALE;
    }

     
    function forwardFunds() public onlyOwner {
        require(hasEnded());
        require(softCapReached());

        token.releaseTokenTransfer();
        token.burn(token.balanceOf(this));

         
        token.transferOwnership(msg.sender);

         
        uint256 totalBalance = this.balance;
        LOTTERY_FUND_ADDRESS.transfer((totalBalance.mul(LOTTERY_FUND_SHARE)).div(100));
        OPERATIONS_ADDRESS.transfer((totalBalance.mul(OPERATIONS_SHARE)).div(100));
        PARTNERS_ADDRESS.transfer(this.balance);  
    }
     
    function refund() public {
        require(hasEnded());
        require(!softCapReached() || ((now > END_TIME_SALE + 30 days) && !token.released()));
        uint256 amount = deposits[msg.sender];
        require(amount > 0);
        deposits[msg.sender] = 0;
        msg.sender.transfer(amount);

    }

     

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = (now >= START_TIME_PRESALE && now <= END_TIME_PRESALE) || (now >= START_TIME_SALE && now <= END_TIME_SALE);
        return withinPeriod && !hardCapReached();
    }
     
    function addToWhiteList(address _whitelistAddress) public onlyServiceAgent {
        whitelist[_whitelistAddress] = true;
    }

     
    function removeWhiteList(address _whitelistAddress) public onlyServiceAgent {
        delete whitelist[_whitelistAddress];
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract LuckchemyToken is BurnableToken, StandardToken, Claimable {

    bool public released = false;

    string public constant name = "Luckchemy";

    string public constant symbol = "LUK";

    uint8 public constant decimals = 8;

    uint256 public CROWDSALE_SUPPLY;

    uint256 public OWNERS_AND_PARTNERS_SUPPLY;

    address public constant OWNERS_AND_PARTNERS_ADDRESS = 0x603a535a1D7C5050021F9f5a4ACB773C35a67602;

     
    uint256 public addressCount = 0;

     
    mapping(uint256 => address) public addressMap;
    mapping(address => bool) public addressAvailabilityMap;

     
    mapping(address => bool) public blacklist;

     
    address public serviceAgent;

    event Release();
    event BlacklistAdd(address indexed addr);
    event BlacklistRemove(address indexed addr);

     
    modifier canTransfer() {
        require(released || msg.sender == owner);
        _;
    }

     
    modifier onlyServiceAgent(){
        require(msg.sender == serviceAgent);
        _;
    }


    function LuckchemyToken() public {

        totalSupply_ = 1000000000 * (10 ** uint256(decimals));
        CROWDSALE_SUPPLY = 700000000 * (10 ** uint256(decimals));
        OWNERS_AND_PARTNERS_SUPPLY = 300000000 * (10 ** uint256(decimals));

        addAddressToUniqueMap(msg.sender);
        addAddressToUniqueMap(OWNERS_AND_PARTNERS_ADDRESS);

        balances[msg.sender] = CROWDSALE_SUPPLY;

        balances[OWNERS_AND_PARTNERS_ADDRESS] = OWNERS_AND_PARTNERS_SUPPLY;

        owner = msg.sender;

        Transfer(0x0, msg.sender, CROWDSALE_SUPPLY);

        Transfer(0x0, OWNERS_AND_PARTNERS_ADDRESS, OWNERS_AND_PARTNERS_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
         
        addAddressToUniqueMap(_to);

         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
         
        addAddressToUniqueMap(_to);

         
        return super.transferFrom(_from, _to, _value);
    }

     
    function releaseTokenTransfer() public onlyOwner {
        released = true;
        Release();
    }

     
    function addBlacklistItem(address _blackAddr) public onlyServiceAgent {
        blacklist[_blackAddr] = true;

        BlacklistAdd(_blackAddr);
    }

     
    function removeBlacklistItem(address _blackAddr) public onlyServiceAgent {
        delete blacklist[_blackAddr];
    }

     
    function addAddressToUniqueMap(address _addr) private returns (bool) {
        if (addressAvailabilityMap[_addr] == true) {
            return true;
        }

        addressAvailabilityMap[_addr] = true;
        addressMap[addressCount++] = _addr;

        return true;
    }

     
    function getUniqueAddressByIndex(uint256 _addressIndex) public view returns (address) {
        return addressMap[_addressIndex];
    }

     
    function changeServiceAgent(address _addr) public onlyOwner {
        serviceAgent = _addr;
    }

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