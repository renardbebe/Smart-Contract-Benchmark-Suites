 

pragma solidity ^0.4.18;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
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
 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract Haltable is Ownable {

     
    bool public halted = false;
     
    function Haltable() public {}

     
    modifier stopIfHalted {
      require(!halted);
      _;
    }

     
    modifier runIfHalted{
      require(halted);
      _;
    }

     
    function halt() onlyOwner stopIfHalted public {
        halted = true;
    }
     
    function unHalt() onlyOwner runIfHalted public {
        halted = false;
    }
}

contract UpgradeAgent is SafeMath {
  address public owner;
  bool public isUpgradeAgent;
  function upgradeFrom(address _from, uint256 _value) public;
  function setOriginalSupply() public;
}

contract MiBoodleToken is ERC20,SafeMath,Haltable {

     
    bool public isMiBoodleToken = false;

     
    string public constant name = "miBoodle";
    string public constant symbol = "MIBO";
    uint256 public constant decimals = 18;  

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;
     
    mapping (address => mapping (address => uint256)) allowedToBurn;

     
    mapping (address => uint256) investment;

    address public upgradeMaster;
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;
    bool public upgradeAgentStatus = false;

     
      
    uint256 public start;
     
    uint256 public end;
     
    uint256 public preFundingStart;
     
    uint256 public preFundingtokens;
     
    uint256 public fundingTokens;
     
    uint256 public maxTokenSupply = 600000000 ether;
     
    uint256 public maxTokenSale = 200000000 ether;
     
    uint256 public maxTokenForPreSale = 100000000 ether;
     
    address public multisig;
     
    address public vault;
     
    bool public isCrowdSaleFinalized = false;
     
    uint256 minInvest = 1 ether;
     
    uint256 maxInvest = 50 ether;
     
    bool public isTransferEnable = false;
     
    bool public isReleasedOnce = false;

     
    event Allocate(address _address,uint256 _value);
    event Burn(address owner,uint256 _value);
    event ApproveBurner(address owner, address canBurn, uint256 value);
    event BurnFrom(address _from,uint256 _value);
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    event UpgradeAgentSet(address agent);
    event Deposit(address _investor,uint256 _value);

    function MiBoodleToken(uint256 _preFundingtokens,uint256 _fundingTokens,uint256 _preFundingStart,uint256 _start,uint256 _end) public {
        upgradeMaster = msg.sender;
        isMiBoodleToken = true;
        preFundingtokens = _preFundingtokens;
        fundingTokens = _fundingTokens;
        preFundingStart = safeAdd(now, _preFundingStart);
        start = safeAdd(now, _start);
        end = safeAdd(now, _end);
    }

     
     
    function setMinimumEtherToAccept(uint256 _minInvest) public stopIfHalted onlyOwner {
        minInvest = _minInvest;
    }

     
     
    function setMaximumEtherToAccept(uint256 _maxInvest) public stopIfHalted onlyOwner {
        maxInvest = _maxInvest;
    }

     
     
    function setPreFundingStartTime(uint256 _preFundingStart) public stopIfHalted onlyOwner {
        preFundingStart = now + _preFundingStart;
    }

     
     
    function setFundingStartTime(uint256 _start) public stopIfHalted onlyOwner {
        start = now + _start;
    }

     
     
    function setFundingEndTime(uint256 _end) public stopIfHalted onlyOwner {
        end = now + _end;
    }

     
     
    function setTransferEnable(bool _isTransferEnable) public stopIfHalted onlyOwner {
        isTransferEnable = _isTransferEnable;
    }

     
     
    function setPreFundingtokens(uint256 _preFundingtokens) public stopIfHalted onlyOwner {
        preFundingtokens = _preFundingtokens;
    }

     
     
    function setFundingtokens(uint256 _fundingTokens) public stopIfHalted onlyOwner {
        fundingTokens = _fundingTokens;
    }

     
     
    function setMultisigWallet(address _multisig) onlyOwner public {
        require(_multisig != 0);
        multisig = _multisig;
    }

     
     
    function setMiBoodleVault(address _vault) onlyOwner public {
        require(_vault != 0);
        vault = _vault;
    }

     
     
     
    function cashInvestment(address _investor,uint256 _tokens) onlyOwner stopIfHalted external {
         
        require(_investor != 0);
         
        require(_tokens > 0);
         
        require(now >= preFundingStart && now <= end);
        if (now < start && now >= preFundingStart) {
             
            require(safeAdd(totalSupply, _tokens) <= maxTokenForPreSale);
        } else {
             
            require(safeAdd(totalSupply, _tokens) <= maxTokenSale);
        }
         
        assignTokens(_investor,_tokens);
    }

     
     
    function assignTokens(address _investor, uint256 _tokens) internal {
         
        totalSupply = safeAdd(totalSupply,_tokens);
         
        balances[_investor] = safeAdd(balances[_investor],_tokens);
         
        Allocate(_investor, _tokens);
    }

     
    function withdraw() external onlyOwner {
         
        require(now <= end && multisig != address(0));
         
        require(!isReleasedOnce);
         
        require(address(this).balance >= 200 ether);
         
        isReleasedOnce = true;
         
        assert(multisig.send(200 ether));
    }

     
    function finalizeCrowdSale() external {
        require(!isCrowdSaleFinalized);
        require(multisig != 0 && vault != 0 && now > end);
        require(safeAdd(totalSupply,250000000 ether) <= maxTokenSupply);
        assignTokens(multisig, 250000000 ether);
        require(safeAdd(totalSupply,150000000 ether) <= maxTokenSupply);
        assignTokens(vault, 150000000 ether);
        isCrowdSaleFinalized = true;
        require(multisig.send(address(this).balance));
    }

     
    function() payable stopIfHalted external {
         
        require(now <= end && now >= preFundingStart);
         
        require(msg.value >= minInvest);
         
        require(safeAdd(investment[msg.sender],msg.value) <= maxInvest);

         
        uint256 createdTokens;
        if (now < start) {
            createdTokens = safeMul(msg.value,preFundingtokens);
             
            require(safeAdd(totalSupply, createdTokens) <= maxTokenForPreSale);
        } else {
            createdTokens = safeMul(msg.value,fundingTokens);
             
            require(safeAdd(totalSupply, createdTokens) <= maxTokenSale);
        }

         
        investment[msg.sender] = safeAdd(investment[msg.sender],msg.value);
        
         
        assignTokens(msg.sender,createdTokens);
        Deposit(msg.sender,createdTokens);
    }

     
     
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

     
     
     
    function allowanceToBurn(address _owner, address _spender) public constant returns (uint) {
        return allowedToBurn[_owner][_spender];
    }

     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool ok) {
         
        require(isTransferEnable);
         
         
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
         
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
         
        require(isTransferEnable);
         
         
        require(_from != 0 && _to != 0 && _value > 0);
         
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool ok) {
         
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function approveForBurn(address _canBurn, uint _value) public returns (bool ok) {
         
        require(_canBurn != 0);
        allowedToBurn[msg.sender][_canBurn] = _value;
        ApproveBurner(msg.sender, _canBurn, _value);
        return true;
    }

     
     
     
     
    function burn(uint _value) public returns (bool ok) {
         
        require(now >= end);
         
        require(_value > 0);
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        totalSupply = safeSub(totalSupply,_value);
        Burn(msg.sender, _value);
        return true;
    }

     
     
     
     
     
     
    function burnFrom(address _from, uint _value) public returns (bool ok) {
         
        require(now >= end);
         
        require(_from != 0 && _value > 0);
         
        require(allowedToBurn[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        totalSupply = safeSub(totalSupply,_value);
        allowedToBurn[_from][msg.sender] = safeSub(allowedToBurn[_from][msg.sender],_value);
        BurnFrom(_from, _value);
        return true;
    }

     

     
     
    function upgrade(uint256 value) external {
        /*if (getState() != State.Success) throw;  
        require(upgradeAgentStatus);  

         
        require (value > 0 && upgradeAgent.owner() != 0x0);
        require (value <= balances[msg.sender]);

         
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
     
     
    function setUpgradeAgent(address agent) external onlyOwner {
        require(agent != 0x0 && msg.sender == upgradeMaster);
        upgradeAgent = UpgradeAgent(agent);
        require (upgradeAgent.isUpgradeAgent());
         
        upgradeAgentStatus = true;
        upgradeAgent.setOriginalSupply();
        UpgradeAgentSet(upgradeAgent);
    }

     
     
     
    function setUpgradeMaster(address master) external {
        require (master != 0x0 && msg.sender == upgradeMaster);
        upgradeMaster = master;
    }
}