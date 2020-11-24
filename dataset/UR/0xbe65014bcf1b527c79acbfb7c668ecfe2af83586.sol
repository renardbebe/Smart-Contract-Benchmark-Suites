 

pragma solidity ^0.4.18;

 

 
 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

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


 

contract BurnableToken is StandardToken {
    using SafeMath for uint256;

    event Burn(address indexed from, uint256 amount);
    event BurnRewardIncreased(address indexed from, uint256 value);

     
    function() payable public {
        if(msg.value > 0){
            BurnRewardIncreased(msg.sender, msg.value);    
        }
    }

     
    function burnReward(uint256 _amount) public constant returns(uint256){
        return this.balance.mul(_amount).div(totalSupply);
    }

     
    function burn(address _from, uint256 _amount) internal returns(bool){
        require(balances[_from] >= _amount);
        
        uint256 reward = burnReward(_amount);
        assert(this.balance - reward > 0);

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
         
        
        _from.transfer(reward);
        Burn(_from, _amount);
        Transfer(_from, address(0), _amount);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            return burn(msg.sender, _value);
        }else{
            return super.transfer(_to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            var _allowance = allowed[_from][msg.sender];
             
            allowed[_from][msg.sender] = _allowance.sub(_value);
            return burn(_from, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

}



 

 
contract WorldCoin is BurnableToken, MintableToken, HasNoContracts, HasNoTokens {  
    using SafeMath for uint256;

    string public name = "World Coin Network";
    string public symbol = "WCN";
    uint256 public decimals = 18;


     
    modifier canTransfer() {
        require(mintingFinished);
        _;
    }
    
    function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
        return BurnableToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        return BurnableToken.transferFrom(_from, _to, _value);
    }

}

 
contract WorldCoinCrowdsale is Ownable, HasNoContracts, HasNoTokens {
    using SafeMath for uint256;

    uint32 private constant PERCENT_DIVIDER = 100;

    WorldCoin public token;

    struct Round {
        uint256 start;       
        uint256 end;         
        uint256 rate;        
    }
    Round[] public rounds;   


    uint256 public founderPercent;       
    uint256 public partnerBonusPercent;  
    uint256 public referralBonusPercent; 
    uint256 public hardCap;              
    uint256 public totalCollected;       
    uint256 public tokensMinted;         
    bool public finalized;               

     
    function WorldCoinCrowdsale (
        uint256 _founderPercent,
        uint256 _partnerBonusPercent,
        uint256 _referralBonusPercent,
        uint256 _hardCap,
        uint256[] roundStarts,
        uint256[] roundEnds,
        uint256[] roundRates
    ) public {

         
        require(_hardCap > 0);                     
        require(
            (roundStarts.length > 0)  &&                 
            (roundStarts.length == roundEnds.length) &&
            (roundStarts.length == roundRates.length)
        );                   
        uint256 prevRoundEnd = now;
        rounds.length = roundStarts.length;              
        for(uint8 i=0; i < roundStarts.length; i++){
            rounds[i] = Round(roundStarts[i], roundEnds[i], roundRates[i]);
            Round storage r = rounds[i];
            require(prevRoundEnd <= r.start);
            require(r.start < r.end);
            require(r.rate > 0);
            prevRoundEnd = rounds[i].end;
        }

        hardCap = _hardCap;
        partnerBonusPercent = _partnerBonusPercent;
        referralBonusPercent = _referralBonusPercent;
        founderPercent = _founderPercent;
         
         

        token = new WorldCoin();
    }

     
    function currentRoundNum() constant public returns(uint8) {
        for(uint8 i=0; i < rounds.length; i++){
            if( (now > rounds[i].start) && (now <= rounds[i].end) ) return i+1;
        }
        return 0;
    }
     
    function currentRate() constant public returns(uint256) {
        uint8 roundNum = currentRoundNum();
        if(roundNum == 0) {
            return 0;
        }else{
            return rounds[roundNum-1].rate;
        }
    }

    function firstRoundStartTimestamp() constant public returns(uint256){
        return rounds[0].start;
    }
    function lastRoundEndTimestamp() constant public returns(uint256){
        return rounds[rounds.length - 1].end;
    }

      
    function crowdsaleRunning() constant public returns(bool){
        return !finalized && (tokensMinted < hardCap) && (currentRoundNum() > 0);
    }

     
    function() payable public {
        sale(msg.sender, 0x0);
    } 

     
    function sale(address buyer, address partner) public payable {
        if(!crowdsaleRunning()) revert();
        require(msg.value > 0);
        uint256 rate = currentRate();
        assert(rate > 0);

        uint256 referralTokens; uint256 partnerTokens; uint256 ownerTokens;
        uint256 tokens = rate.mul(msg.value);
        assert(tokens > 0);
        totalCollected = totalCollected.add(msg.value);
        if(partner == 0x0){
            ownerTokens     = tokens.mul(founderPercent).div(PERCENT_DIVIDER);
            mintTokens(buyer, tokens);
            mintTokens(owner, ownerTokens);
        }else{
            partnerTokens   = tokens.mul(partnerBonusPercent).div(PERCENT_DIVIDER);
            referralTokens  = tokens.mul(referralBonusPercent).div(PERCENT_DIVIDER);
            ownerTokens     = (tokens.add(partnerTokens).add(referralTokens)).mul(founderPercent).div(PERCENT_DIVIDER);
            
            uint256 totalBuyerTokens = tokens.add(referralTokens);
            mintTokens(buyer, totalBuyerTokens);
            mintTokens(partner, partnerTokens);
            mintTokens(owner, ownerTokens);
        }
    }

     
    function saleNonEther(address beneficiary, uint256 amount, string  ) public onlyOwner {
        mintTokens(beneficiary, amount);
    }

     
    function setRoundRate(uint32 roundNum, uint256 rate) public onlyOwner {
        require(roundNum < rounds.length);
        rounds[roundNum].rate = rate;
    }


     
    function claimEther() public onlyOwner {
        if(this.balance > 0){
            owner.transfer(this.balance);
        }
    }

     
    function finalizeCrowdsale() public {
        require ( (now > lastRoundEndTimestamp()) || (totalCollected == hardCap) || (msg.sender == owner) );
        finalized = token.finishMinting();
        token.transferOwnership(owner);
        if(this.balance > 0){
            owner.transfer(this.balance);
        }
    }

     
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);
        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));
    }
}