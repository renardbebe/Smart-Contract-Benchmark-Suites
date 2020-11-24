 

pragma solidity ^0.4.18;

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


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
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

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


contract HireGoToken is MintableToken, BurnableToken {

    string public constant name = "HireGo";
    string public constant symbol = "HGO";
    uint32 public constant decimals = 18;

    function HireGoToken() public {
        totalSupply = 100000000E18;   
        balances[owner] = totalSupply;  
    }

}


contract HireGoCrowdsale is Ownable {

    using SafeMath for uint;

    HireGoToken public token = new HireGoToken();
    uint totalSupply = token.totalSupply();

    bool public isRefundAllowed;

    uint public icoStartTime;
    uint public icoEndTime;
    uint public totalWeiRaised;
    uint public weiRaised;
    uint public hardCap;  
    uint public tokensDistributed;  
    uint public foundersTokensUnlockTime;

     
    uint internal baseBonus1 = 135;
    uint internal baseBonus2 = 130;
    uint internal baseBonus3 = 125;
    uint internal baseBonus4 = 115;
    uint public manualBonus;
     

    uint public waveCap1;
    uint public waveCap2;
    uint public waveCap3;
    uint public waveCap4;

    uint public rate;  
    uint private icoMinPurchase;  

    address[] public investors_number;
    address private wallet;  

    mapping (address => uint) public orderedTokens;
    mapping (address => uint) contributors;

    event FundsWithdrawn(address _who, uint256 _amount);

    modifier hardCapNotReached() {
        require(totalWeiRaised < hardCap);
        _;
    }

    modifier crowdsaleEnded() {
        require(now > icoEndTime);
        _;
    }

    modifier foundersTokensUnlocked() {
        require(now > foundersTokensUnlockTime);
        _;
    }

    modifier crowdsaleInProgress() {
        bool withinPeriod = (now >= icoStartTime && now <= icoEndTime);
        require(withinPeriod);
        _;
    }

    function HireGoCrowdsale(uint _icoStartTime, uint _icoEndTime, address _wallet) public {
        require (
          _icoStartTime > now &&
          _icoEndTime > _icoStartTime
        );

        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        foundersTokensUnlockTime = icoEndTime.add(180 days);
        wallet = _wallet;

        rate = 250 szabo;  

        hardCap = 11836 ether;
        icoMinPurchase = 50 finney;  
        isRefundAllowed = false;

        waveCap1 = 2777 ether;
        waveCap2 = waveCap1.add(2884 ether);
        waveCap3 = waveCap2.add(4000 ether);
        waveCap4 = waveCap3.add(2174 ether);
    }

     
    function() public payable {
        buyTokens();
    }

     
    function buyTokens() public payable crowdsaleInProgress hardCapNotReached {
        require(msg.value > 0);

         
        calculatePurchaseAndBonuses(msg.sender, msg.value);
    }

     
    function getInvestorCount() public view returns (uint) {
        return investors_number.length;
    }

     
     
    function toggleRefunds() public onlyOwner {
        isRefundAllowed = true;
    }

     
     
    function sendOrderedTokens() public onlyOwner crowdsaleEnded {
        address investor;
        uint tokensCount;
        for(uint i = 0; i < investors_number.length; i++) {
            investor = investors_number[i];
            tokensCount = orderedTokens[investor];
            assert(tokensCount > 0);
            orderedTokens[investor] = 0;
            token.transfer(investor, tokensCount);
        }
    }

     
     
     
    function refundInvestors() public onlyOwner {
        require(now >= icoEndTime);
        require(isRefundAllowed);
        require(msg.sender.balance > 0);

        address investor;
        uint contributedWei;
        uint tokens;
        for(uint i = 0; i < investors_number.length; i++) {
            investor = investors_number[i];
            contributedWei = contributors[investor];
            tokens = orderedTokens[investor];
            if(contributedWei > 0) {
                totalWeiRaised = totalWeiRaised.sub(contributedWei);
                weiRaised = weiRaised.sub(contributedWei);
                if(weiRaised<0){
                  weiRaised = 0;
                }
                contributors[investor] = 0;
                orderedTokens[investor] = 0;
                tokensDistributed = tokensDistributed.sub(tokens);
                investor.transfer(contributedWei);  
            }
        }
    }

     
    function withdraw() public onlyOwner {
        uint to_send = weiRaised;
        weiRaised = 0;
        FundsWithdrawn(msg.sender, to_send);
        wallet.transfer(to_send);
    }

    function burnUnsold() public onlyOwner crowdsaleEnded {
        uint tokensLeft = totalSupply.sub(tokensDistributed);
        token.burn(tokensLeft);
    }

    function finishIco() public onlyOwner {
        icoEndTime = now;
    }

    function distribute_for_founders() public onlyOwner foundersTokensUnlocked {
        uint to_send = 40000000E18;  
        checkAndMint(to_send);
        token.transfer(wallet, to_send);
    }

    function transferOwnershipToken(address _to) public onlyOwner {
        token.transferOwnership(_to);
    }

     

     
    function calculatePurchaseAndBonuses(address _beneficiary, uint _weiAmount) internal {
        if (now >= icoStartTime && now < icoEndTime) require(_weiAmount >= icoMinPurchase);

        uint cleanWei;  
        uint change;
        uint _tokens;

         
        if (_weiAmount.add(totalWeiRaised) > hardCap) {
            cleanWei = hardCap.sub(totalWeiRaised);
            change = _weiAmount.sub(cleanWei);
        }
        else cleanWei = _weiAmount;

        assert(cleanWei > 4);  

        _tokens = cleanWei.div(rate).mul(1 ether);

        if (contributors[_beneficiary] == 0) investors_number.push(_beneficiary);

        _tokens = calculateBonus(_tokens);
        checkAndMint(_tokens);

        contributors[_beneficiary] = contributors[_beneficiary].add(cleanWei);
        weiRaised = weiRaised.add(cleanWei);
        totalWeiRaised = totalWeiRaised.add(cleanWei);
        tokensDistributed = tokensDistributed.add(_tokens);
        orderedTokens[_beneficiary] = orderedTokens[_beneficiary].add(_tokens);

        if (change > 0) _beneficiary.transfer(change);
    }

     
    function calculateBonus(uint _baseAmount) internal returns (uint) {
        require(_baseAmount > 0);

        if (now >= icoStartTime && now < icoEndTime) {
            return calculateBonusIco(_baseAmount);
        }
        else return _baseAmount;
    }

     
     
    function calculateBonusIco(uint _baseAmount) internal returns(uint) {
        if(totalWeiRaised < waveCap1) {
            return _baseAmount.mul(baseBonus1).div(100);
        }
        else if(totalWeiRaised >= waveCap1 && totalWeiRaised < waveCap2) {
            return _baseAmount.mul(baseBonus2).div(100);
        }
        else if(totalWeiRaised >= waveCap2 && totalWeiRaised < waveCap3) {
            return _baseAmount.mul(baseBonus3).div(100);
        }
        else if(totalWeiRaised >= waveCap3 && totalWeiRaised < waveCap4) {
            return _baseAmount.mul(baseBonus4).div(100);
        }
        else {
             
            return _baseAmount;
        }
    }

     
     
    function checkAndMint(uint _amount) internal {
        uint required = tokensDistributed.add(_amount);
        if(required > totalSupply) token.mint(this, required.sub(totalSupply));
    }
}