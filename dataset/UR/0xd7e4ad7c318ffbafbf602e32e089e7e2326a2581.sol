 

pragma solidity ^0.4.18;

 

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

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

  
  function tokenFallback(address from_, uint256 value_, bytes data_) pure external {
    from_;
    value_;
    data_;
    revert();
  }

}

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
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
    totalSupply_ = totalSupply_.add(_amount);
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

 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

 

contract DOCTToken is MintableToken, ERC827Token, NoOwner {
    string public symbol = 'DOCT';
    string public name = 'DocTailor';
    uint8 public constant decimals = 8;

    address founder;                 
    bool public transferEnabled;     

    function setFounder(address _founder) onlyOwner public {
        founder = _founder;
    }
    function setTransferEnabled(bool enable) onlyOwner public {
        transferEnabled = enable;
    }
    modifier canTransfer() {
        require( transferEnabled || msg.sender == founder || msg.sender == owner);
        _;
    }
    
    function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    function transfer(address _to, uint256 _value, bytes _data) canTransfer public returns (bool) {
        return super.transfer(_to, _value, _data);
    }
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) canTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value, _data);
    }
}

 
contract DOCTCrowdsale is Ownable, HasNoContracts, CanReclaimToken, Destructible {
    using SafeMath for uint256;

    uint256 constant  DOCT_TO_ETH_DECIMALS = 10000000000;     

    DOCTToken public token;

    struct Round {
        uint256 start;           
        uint256 end;             
        uint256 rate;            
        uint256 rateBulk;        
        uint256 bulkThreshold;   
    }
    Round[] public rounds;           
    uint256 public hardCap;          
    uint256 public tokensMinted;     
    bool public finalized;           

    function DOCTCrowdsale (
        uint256 _hardCap,
        uint256[] roundStarts,
        uint256[] roundEnds,
        uint256[] roundRates,
        uint256[] roundRatesBulk,
        uint256[] roundBulkThreshold
    ) public {
        token = new DOCTToken();
        token.setFounder(owner);
        token.setTransferEnabled(false);

        tokensMinted = token.totalSupply();

         
        require(_hardCap > 0);                     
        hardCap = _hardCap;

        initRounds(roundStarts, roundEnds, roundRates, roundRatesBulk, roundBulkThreshold);
    }
    function initRounds(uint256[] roundStarts, uint256[] roundEnds, uint256[] roundRates, uint256[] roundRatesBulk, uint256[] roundBulkThreshold) internal {
        require(
            (roundStarts.length > 0)  &&                 
            (roundStarts.length == roundEnds.length) &&
            (roundStarts.length == roundRates.length) &&
            (roundStarts.length == roundRatesBulk.length) &&
            (roundStarts.length == roundBulkThreshold.length)
        );                   
        uint256 prevRoundEnd = now;
        rounds.length = roundStarts.length;              
        for(uint8 i=0; i < roundStarts.length; i++){
            rounds[i] = Round({start:roundStarts[i], end:roundEnds[i], rate:roundRates[i], rateBulk:roundRatesBulk[i], bulkThreshold:roundBulkThreshold[i]});
            Round storage r = rounds[i];
            require(prevRoundEnd <= r.start);
            require(r.start < r.end);
            require(r.bulkThreshold > 0);
            prevRoundEnd = rounds[i].end;
        }
    }
    function setRound(uint8 roundNum, uint256 start, uint256 end, uint256 rate, uint256 rateBulk, uint256 bulkThreshold) onlyOwner external {
        uint8 round = roundNum-1;
        if(round > 0){
            require(rounds[round - 1].end <= start);
        }
        if(round < rounds.length - 1){
            require(end <= rounds[round + 1].start);   
        }
        rounds[round].start = start;
        rounds[round].end = end;
        rounds[round].rate = rate;
        rounds[round].rateBulk = rateBulk;
        rounds[round].bulkThreshold = bulkThreshold;
    }


     
    function() payable public {
        require(msg.value > 0);
        require(crowdsaleRunning());

        uint256 rate = currentRate(msg.value);
        require(rate > 0);
        uint256 tokens = rate.mul(msg.value).div(DOCT_TO_ETH_DECIMALS);
        mintTokens(msg.sender, tokens);
    }

     
    function saleNonEther(address beneficiary, uint256 amount, string  ) onlyOwner external{
        mintTokens(beneficiary, amount);
    }

     
    function bulkTokenSend(address[] beneficiaries, uint256[] amounts, string  ) onlyOwner external{
        require(beneficiaries.length == amounts.length);
        for(uint32 i=0; i < beneficiaries.length; i++){
            mintTokens(beneficiaries[i], amounts[i]);
        }
    }
     
    function bulkTokenSend(address[] beneficiaries, uint256 amount, string  ) onlyOwner external{
        require(amount > 0);
        for(uint32 i=0; i < beneficiaries.length; i++){
            mintTokens(beneficiaries[i], amount);
        }
    }

      
    function crowdsaleRunning() constant public returns(bool){
        return !finalized && (tokensMinted < hardCap) && (currentRoundNum() > 0);
    }

     
    function currentRoundNum() view public returns(uint8) {
        for(uint8 i=0; i < rounds.length; i++){
            if( (now > rounds[i].start) && (now <= rounds[i].end) ) return i+1;
        }
        return 0;
    }
     
    function currentRate(uint256 amount) view public returns(uint256) {
        uint8 roundNum = currentRoundNum();
        if(roundNum == 0) {
            return 0;
        }else{
            uint8 round = roundNum-1;
            if(amount < rounds[round].bulkThreshold){
                return rounds[round].rate;
            }else{
                return rounds[round].rateBulk;
            }
        }
    }

     
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);
        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));
    }

     
    function claimEther() public onlyOwner {
        if(this.balance > 0){
            owner.transfer(this.balance);
        }
    }

     
    function finalizeCrowdsale() onlyOwner public {
        finalized = true;
        assert(token.finishMinting());
        token.setTransferEnabled(true);
        token.transferOwnership(owner);
        claimEther();
    }

}