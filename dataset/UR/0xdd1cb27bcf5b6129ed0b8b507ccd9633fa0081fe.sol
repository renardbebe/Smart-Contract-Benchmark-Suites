 

pragma solidity ^0.5.1;

 



library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }

}

interface Token {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }

}

contract ForeignToken {
    function balanceOf(address _owner) pure public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract SultanChain is StandardToken {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => bool) public Claimed; 

    mapping (address => uint256) allocations;    
    
     
    mapping(address => bool) public frozenAccount;
    
    bool private unFreeze;

     
    address[] public receivers;

     
    event FundsFrozen(address target, bool frozen);
    event AccountFrozenError();
    event Refund(address target, uint256 amount);

    uint256 public basePercent = 100;

    string constant tokenName = "Sultan Chain";
    string constant tokenSymbol = "STN";
    uint8  constant tokenDecimals = 18;

    uint public deadline = now + 60 * 1 days;
    uint public round2 = now + 60 * 1 days;
    uint public round1 = now + 60 * 1 days;
    
    uint256 public totalSupply = 7000000e18;
    uint256 public totalDistributed;
    uint256 public constant requestMinimum = 1 ether / 1000;  
    uint256 public tokensPerEth = 1000e18;

    uint public targetAirdrop = 100000;
    uint public progressAirdrop = 0;
    uint256 public unlockDate;

    uint256 constant AirSelfDropDonation = 3000000e18;
    uint256 constant marketingPromotion = 500000e18;     
    uint256 constant adminSalary = 500000e18;     
    uint256 constant stakingRewards = 1000000e18;     
    uint256 constant devMaintenance = 1000000e18;     
    uint256 constant lockDeposit = 1000000e18;     

    address wallet_marketingPromotion = 0x431e5f0C520Ad95CcD7C1063fAa088732BA059F6;     
    address wallet_adminSalary = 0x28c35c792B78E46D7d12Cae17d4A4D1A30c36Ff1;     
    address wallet_stakingRewards = 0x91dc5b87a10cdCD37f707dFC13918DA991d7a37b;     
    address wallet_devMaintenance = 0xeA110053959380Df3a91b97c57d54c976A210B3b;     
    address wallet_lockDeposit = 0xc1AE350AE6ffE65cE10756184fA1cdEd701de1ba;     

    address payable ethFundDeposit = 0x7b88D2A62682749919e1e0401200139624cc5A82;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);
    
    event Burn(address indexed burner, uint256 value);
    
    event Add(uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public payable StandardToken(tokenName, tokenSymbol, tokenDecimals) {
        unFreeze = true;
        owner = msg.sender;
        unlockDate = now + 12 * 30 days;
        distr(owner, devMaintenance);
        distr(wallet_marketingPromotion, marketingPromotion);
        distr(wallet_adminSalary, adminSalary);
        distr(wallet_stakingRewards, stakingRewards);
        distr(wallet_lockDeposit, lockDeposit);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    function Distribute(address _participant, uint _amount) onlyOwner internal {

        require( _amount > 0 );      
        require( totalDistributed < totalSupply );
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

         
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }
    
    function DistributeAirdrop(address _participant, uint _amount) onlyOwner external {        
        Distribute(_participant, _amount);
    }

    function DistributeAirdropMultiple(address[] calldata _addresses, uint _amount) onlyOwner external {        
        for (uint i = 0; i < _addresses.length; i++) Distribute(_addresses[i], _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 bonus = 0;
        uint256 countbonus = 0;
        uint256 bonusCond1 = 1 ether / 10;
        uint256 bonusCond2 = 5 ether / 10;
        uint256 bonusCond3 = 1 ether;

        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;

        if (msg.value >= requestMinimum && now < deadline && now < round1 && now < round2) {
            if(msg.value >= bonusCond1 && msg.value < bonusCond2){
                countbonus = tokens * 10 / 100;
            }else if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 20 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 35 / 100;
            }
        }else if(msg.value >= requestMinimum && now < deadline && now > round1 && now < round2){
            if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 2 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 3 / 100;
            }
        }else{
            countbonus = 0;
        }

        bonus = tokens + countbonus;
        
        if (tokens == 0) {
            uint256 valdrop = 5e18;
            if (Claimed[investor] == false && progressAirdrop <= targetAirdrop ) {
                distr(investor, valdrop);
                Claimed[investor] = true;
                progressAirdrop++;
            }else{
                require( msg.value >= requestMinimum );
            }
        }else if(tokens > 0 && msg.value >= requestMinimum){
            if( now >= deadline && now >= round1 && now < round2){
                distr(investor, tokens);
            }else{
                if(msg.value >= bonusCond1){
                    distr(investor, bonus);
                }else{
                    distr(investor, tokens);
                }   
            }
        }else{
            require( msg.value >= requestMinimum );
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        ethFundDeposit.transfer(msg.value);
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_amount <= balances[msg.sender]);
        require(_to != address(0));

         
        if (frozenAccount[msg.sender] && !unFreeze) {
            emit AccountFrozenError();
            return false;
        }

         
        receivers.push(_to);

        uint256 tokensToBurn = findOnePercent(_amount);
        uint256 tokensToTransfer = _amount.sub(tokensToBurn);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(tokensToTransfer);

        totalSupply = totalSupply.sub(tokensToBurn);

        emit Transfer(msg.sender, _to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) public returns (bool) { 
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

         
        if (frozenAccount[from] && !unFreeze) {
            emit AccountFrozenError();
            return false;
        }

         
        receivers.push(to);

        balances[from] = balances[from].sub(value);
        uint256 tokensToBurn = findOnePercent(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);
        balances[to] = balances[to].add(tokensToTransfer);
        totalSupply = totalSupply.sub(tokensToBurn);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, address(0), tokensToBurn);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) pure public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= balances[account]);
        totalSupply = totalSupply.sub(amount);
        balances[account] = balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= allowed[account][msg.sender]);
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(amount);
        _burn(account, amount);
    }
    
    function findOnePercent(uint256 value) public view returns (uint256)  {
        uint256 onePercent = value.mul(basePercent).div(10000);   
        return onePercent;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function refund(address _to, uint256 _value) public payable onlyOwner returns (bool) {
         
        require(transferFrom(_to, owner, _value), "Transfer failed.");
        emit Refund(_to, _value);
        return true;
    }

     
    function getAccountList() public view returns (address[] memory) {
        address[] memory v = new address[](receivers.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            v[i] = receivers[i];
        }
        return v;
    }

     
    function changeFreezeStatus(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FundsFrozen(target, freeze);
    }

    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

     

}