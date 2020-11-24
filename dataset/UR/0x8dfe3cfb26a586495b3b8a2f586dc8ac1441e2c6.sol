 

pragma solidity ^0.4.19;
 
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

contract owned {
    address public owner;
    address public newOwner;

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract StandardToken {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    uint256 public totalSupply;  
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
     
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


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_to != address(0));

      var _allowance = allowed[_from][msg.sender];

       
       

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

       
       
       
       
      require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     
    function increaseApproval (address _spender, uint _addedValue) public
      returns (bool success) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
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


contract UbecoinICO is owned {
    using SafeMath for uint256;
    string public version = "1.0";
    address private WITHDRAW_WALLET;
    uint256 public totalSold = 0;
    uint256 public soldOnStage = 0;
    uint8 public currentStage = 0;
    Ubecoin public rewardToken;


    uint256[] tokensRate = [7000,4200];
    uint256[] tokensCap = [50000000,80000000];
    mapping(address=>uint256) investments;
    uint256 limit_on_beneficiary = 1000 * 1000 ether;

    function investmentsOf(address beneficiary) public constant returns(uint256) {
      return investments[beneficiary];
    }
  
    function availableOnStage() public constant returns(uint256) {
        return tokensCap[currentStage].mul(1 ether).sub(soldOnStage);
    }

    function createTokenContract() internal returns (Ubecoin) {
      return new Ubecoin();
    }

    function currentStageTokensCap() public constant returns(uint256) {
      return tokensCap[currentStage];
    }
    function currentStageTokensRate() public constant returns(uint256) {
      return tokensRate[currentStage];
    }

    function UbecoinICO() payable owned() {
        owner = msg.sender;
        WITHDRAW_WALLET = msg.sender; 
        rewardToken = createTokenContract();
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable {
      bool canBuy = investmentsOf(beneficiary) < limit_on_beneficiary;
      bool validPurchase = beneficiary != 0x0 && msg.value != 0;
      uint256 currentTokensAmount = availableTokens();
      require(canBuy && validPurchase && currentTokensAmount > 0);
      uint256 boughtTokens;
      uint256 refundAmount = 0;
      
      uint256[2] memory tokensAndRefund = calcMultiStage();
      boughtTokens = tokensAndRefund[0];
      refundAmount = tokensAndRefund[1];

      require(boughtTokens < currentTokensAmount);

      totalSold = totalSold.add(boughtTokens);
      investments[beneficiary] = investments[beneficiary].add(boughtTokens);
      if( soldOnStage >= tokensCap[currentStage].mul(1 ether)) {
        toNextStage();
      } 
      
      rewardToken.transfer(beneficiary,boughtTokens);
      if (refundAmount > 0) 
          refundMoney(refundAmount);

      withdrawFunds(this.balance);
    }

    function forceWithdraw() onlyOwner {
      withdrawFunds(this.balance);
    }

    function calcMultiStage() internal returns(uint256[2]) {
      uint256 stageBoughtTokens;
      uint256 undistributedAmount = msg.value; 
      uint256 _boughtTokens = 0; 
      uint256 undistributedTokens = availableTokens(); 

      while(undistributedAmount > 0 && undistributedTokens > 0) {
        bool needNextStage = false; 
        
        stageBoughtTokens = getTokensAmount(undistributedAmount);
        

        if(totalInvestments(_boughtTokens.add(stageBoughtTokens)) > limit_on_beneficiary){
          stageBoughtTokens = limit_on_beneficiary.sub(_boughtTokens);
          undistributedTokens = stageBoughtTokens; 
        }

        
        if (stageBoughtTokens > availableOnStage()) {
          stageBoughtTokens = availableOnStage();
          needNextStage = true; 
        }
        
        _boughtTokens = _boughtTokens.add(stageBoughtTokens);
        undistributedTokens = undistributedTokens.sub(stageBoughtTokens); 
        undistributedAmount = undistributedAmount.sub(getTokensCost(stageBoughtTokens)); 
        soldOnStage = soldOnStage.add(stageBoughtTokens);
        if (needNextStage) 
          toNextStage();
      }
      return [_boughtTokens,undistributedAmount];
    }


    function setWithdrawWallet(address addressToWithdraw) public onlyOwner {
        require(addressToWithdraw != 0x0);
        WITHDRAW_WALLET = addressToWithdraw;
    }
    function totalInvestments(uint additionalAmount) internal returns (uint256) {
      return investmentsOf(msg.sender).add(additionalAmount);
    }

    function refundMoney(uint256 refundAmount) internal {
      msg.sender.transfer(refundAmount);
    }

    function burnTokens(uint256 amount) public onlyOwner {
      rewardToken.burn(amount);
    }

    function getTokensCost(uint256 _tokensAmount) internal constant returns(uint256) {
      return _tokensAmount.div(tokensRate[currentStage]);
    } 

    function getTokensAmount(uint256 _amountInWei) internal constant returns(uint256) {
      return _amountInWei.mul(tokensRate[currentStage]);
    }

    function toNextStage() internal {
        
        if(currentStage < tokensRate.length && currentStage < tokensCap.length){
          currentStage++;
          soldOnStage = 0;
        }
    }

    function availableTokens() public constant returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function withdrawFunds(uint256 amount) internal {
        WITHDRAW_WALLET.transfer(amount);
    }
}


contract Ubecoin is StandardToken {
      event Burn(address indexed burner, uint256 value);

      string public constant name = "Ubecoin";
      string public constant symbol = "UBE";
      uint8 public constant decimals = 18;
      string public version = "1.0";
      uint256 public totalSupply  = 3000000000 * 1 ether;
      mapping(address=>uint256) premineOf;
      address[] private premineWallets = [
          0xc1b1dCA667619888EF005fA515472FC8058856D9, 
          0x2aB549AF98722F013432698D1D74027c5897843B
      ];

      function Ubecoin() public {
        balances[msg.sender] = totalSupply;
        premineOf[premineWallets[0]] = 300000000 * 1 ether; 
        premineOf[premineWallets[1]] = 2570000000 * 1 ether;
                
        for(uint i = 0; i<premineWallets.length;i++) {
          transfer(premineWallets[i],premineOf[premineWallets[i]]);
        }
      }

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
  }