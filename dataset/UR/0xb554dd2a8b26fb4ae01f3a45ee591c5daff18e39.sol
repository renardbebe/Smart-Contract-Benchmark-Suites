 

pragma solidity ^0.5.1;


 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address payable public owner;
    address payable public reclaimablePocket;  
    address payable public teamWallet;
    constructor(address payable _reclaimablePocket, address payable _teamWallet) public {
        owner = msg.sender;
        reclaimablePocket = _reclaimablePocket;
        teamWallet = _teamWallet;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyTeam {
        require(msg.sender == teamWallet || msg.sender == owner);
        _;
    }
    function transferOwnership(address payable newOwner) onlyOwner public { owner = newOwner; }
    function changeRecPocket(address payable _newRecPocket) onlyTeam public { reclaimablePocket = _newRecPocket;}
    function changeTeamWallet(address payable _newTeamWallet) onlyOwner public { teamWallet = _newTeamWallet;}
}

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);  
    function approve(address _spender, uint _value) external returns (bool);  
    function allowance(address _owner, address _spender) external view returns (uint);  
    event Approval(address indexed _owner, address indexed _spender, uint _value);  
}
interface ERC223 {
    function transfer(address _to, uint _value, bytes calldata _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
interface ERC223ReceivingContract { function tokenFallback(address _from, uint _value, bytes calldata _data) external; }

contract Token is ERC20, ERC223, owned {
    
    using SafeMath for uint;
    
    string internal _symbol;
    string internal _name;
    uint256 internal _decimals = 18;
    string public version = "1.0.0";
    uint internal _totalSupply;
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

     
    uint256 public tokensSold = 0;
    uint256 public remainingTokens;
     
    uint256 public buyPrice;     
    
    constructor(string memory name, string memory symbol, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _totalSupply = totalSupply * 10 ** uint256(_decimals);   
    }
    
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint256) { return _decimals; }
    function totalSupply() public view returns (uint) { return _totalSupply; }
    function balanceOf(address _addr) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
    event purchaseInvoice(address indexed _buyer, uint _tokenReceived, uint _weiSent, uint _weiCost, uint _weiReturned );
}

contract SiBiCryptToken is Token {
   
     
     enum Stages {none, icoStart, icoPaused, icoResumed, icoEnd} 
     Stages currentStage;
    bool payingDividends;
    uint256 freezeTimeStart;
    uint256 constant freezePeriod = 1 * 1 days;
    
    function balanceOf(address _addr) public view returns (uint) {
        return _balanceOf[_addr];
    }
    
    modifier checkICOStatus(){
        require(currentStage == Stages.icoPaused || currentStage == Stages.icoEnd, "Pls, try again after ICO");
        _;
    }
    modifier isPayingDividends(){
        if(payingDividends && now >= (freezeTimeStart+freezePeriod)){
            payingDividends = false;
        }
        require(!payingDividends, "Dividends is being dispatch, pls try later");
        _;
    }
    function payOutDividends() public onlyOwner returns(bool){
        payingDividends = true;
        freezeTimeStart = now;
        return true;
    }
    event thirdPartyTransfer( address indexed _from, address indexed _to, uint _value, address indexed _sentBy ) ;
    event returnedWei(address indexed _fromContract, address indexed _toSender, uint _value);

    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty ;
        transfer(_to, _value, empty);
        return true;
    }

    function transfer(address _to, uint _value, bytes memory _data) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        if(isContract(_to)){
            if(_to == address(this)){
                _transfer(address(this), reclaimablePocket, _value);
            }
            else
            {
                ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
                    _contract.tokenFallback(msg.sender, _value, _data);
            }
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) public checkICOStatus returns (bool) {
        require (_value > 0 && _allowances[_from][msg.sender] >= _value, "insufficient allowance");
        _transfer(_from, _to, _value);
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        emit thirdPartyTransfer(_from, _to, _value, msg.sender);
        return true;
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal checkICOStatus isPayingDividends {
        require(_to != address(0x0), "invalid 'to' address");  
        require(_balanceOf[_from] >= _value, "insufficient funds");  
        require(_balanceOf[_to] + _value > _balanceOf[_to], "overflow err");  
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];  
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value); 
        _balanceOf[_to] = _balanceOf[_to].add(_value);  
        emit Transfer(_from, _to, _value);

         
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }
    
    function approve(address _spender, uint _value) public returns (bool) {
        require(_balanceOf[msg.sender]>=_value);
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return _allowances[_owner][_spender];
    }
}



contract SiBiCryptICO is SiBiCryptToken {
    
  
     
       
    constructor(
            string memory tokenName, string memory tokenSymbol, uint256 initialSupply, address payable _reclaimablePocket, address payable _teamWallet 
        ) Token(tokenName, tokenSymbol, initialSupply) owned(_reclaimablePocket, _teamWallet) public {
        uint toOwnerWallet = (_totalSupply*40)/100;
        uint toTeam = (_totalSupply*15)/100;
         _balanceOf[msg.sender] += toOwnerWallet;
         _balanceOf[teamWallet] += toTeam;
         emit Transfer(address(this),msg.sender,toOwnerWallet);
        emit Transfer(address(this),teamWallet,toTeam);
         tokensSold += toOwnerWallet.add(toTeam);
         remainingTokens = _totalSupply.sub(tokensSold);
         currentStage = Stages.none;
         payingDividends = false;
    }
    
  
     
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;    
    }
     
    function () external payable {
        require(currentStage == Stages.icoStart || currentStage == Stages.icoResumed, "Oops! ICO is not running");
        require(msg.value > 0);
        require(remainingTokens > 0, "Tokens sold out! you may proceed to buy from Token holders");
        
        uint256 weiAmount = msg.value;  
        uint256 tokens = (weiAmount.div(buyPrice)).mul(1*10**18);
        uint256 returnWei;
        
        if(tokens > remainingTokens){
            uint256 newTokens = remainingTokens;
            uint256 newWei = (newTokens.mul(buyPrice)).div(1*10**18);
            returnWei = weiAmount.sub(newWei);
            weiAmount = newWei;
            tokens = newTokens;
        }
        
        tokensSold = tokensSold.add(tokens);  
        remainingTokens = remainingTokens.sub(tokens);  
        if(returnWei > 0){
            msg.sender.transfer(returnWei);
            emit returnedWei(address(this), msg.sender, returnWei);
        }
        
        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(tokens);
        emit Transfer(address(this), msg.sender, tokens);
        emit purchaseInvoice(msg.sender, tokens, msg.value, weiAmount, returnWei);
       
        owner.transfer(weiAmount);  
        if(remainingTokens == 0 ){pauseIco();}
    }
    
     
    function startIco() public onlyOwner  returns(bool) {
        require(currentStage != Stages.icoEnd, "Oops! ICO has been finalized.");
        require(currentStage == Stages.none, "ICO is running already");
        currentStage = Stages.icoStart;
        return true;
    }
    
    function pauseIco() internal {
        require(currentStage != Stages.icoEnd, "Oops! ICO has been finalized.");
        currentStage = Stages.icoPaused;
        owner.transfer(address(this).balance);
    }
    
    function resumeIco() public onlyOwner returns(bool) {
        require(currentStage == Stages.icoPaused, "call denied");
        currentStage = Stages.icoResumed;
        return true;
    }
    
    function ICO_State() public view returns(string memory) {
        if(currentStage == Stages.none) return "Initializing...";
        if(currentStage == Stages.icoPaused) return "Paused!";
        if(currentStage == Stages.icoEnd) return "ICO Stopped!";
        else return "ICO is running...";
    }
    

     
    function endIco() internal {
        currentStage = Stages.icoEnd;
         
        if(remainingTokens > 0){
            _balanceOf[owner] = _balanceOf[owner].add(remainingTokens);
        }
         
        owner.transfer(address(this).balance); 
    }

     
    function finalizeIco() public onlyOwner returns(Stages){
        require(currentStage != Stages.icoEnd );
        if(currentStage == Stages.icoPaused){
            endIco();
            return currentStage;
        }
        else{
            pauseIco();
            return currentStage;
        }
    }
}



 