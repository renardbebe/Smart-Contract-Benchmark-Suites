 

pragma solidity ^0.4.20;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract FairDinkums is StandardToken { 
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    uint256 public tokensPerEth;           
    uint256 public totalEthInWei;          
    address public fundsWallet;            
    uint public startTime;                 
    bool public tokenReleased;
    uint256 public totalDividends;
    mapping (address => uint256) public lastDividends;
    event TokensSold(address Buyer, uint256 Qty);
    
    function FairDinkums() public {
        balances[msg.sender] = 20000 * 1e18;     
        totalSupply = 20000 * 1e18;              
        name = "Fair Dinkums";                   
        decimals = 18;                           
        symbol = "FDK";                          
        tokensPerEth = 1000;                     
        fundsWallet = msg.sender;                
        startTime = now;                         
        tokenReleased = false;                   
    }

    function() public payable {
         
         
         
         
        if (icoOpen()){
             
            require(msg.value > 0 && msg.value <= 20 ether);
            totalEthInWei = totalEthInWei + msg.value;
            uint256 amount = msg.value * tokensPerEth;
            if ((balances[fundsWallet]) < amount) {
                revert();
            }
            TokensSold(msg.sender,amount);
            balances[fundsWallet] = balances[fundsWallet] - amount;
            balances[msg.sender] = balances[msg.sender] + amount;
    
            Transfer(fundsWallet, msg.sender, amount);
    
            fundsWallet.transfer(msg.value);
        } else {
             
            require(msg.value==0);
            updateDivs(msg.sender,dividendsOwing(msg.sender));
        }
    }

    function transfer(address _to, uint256 _value) public released returns (bool success) {
         
        uint256 init_from = dividendsOwing(msg.sender);
        uint256 init_to = dividendsOwing(_to);
         
        require(super.transfer(_to,_value));
         
        updateDivs(msg.sender,init_from);
        updateDivs(_to,init_to);
         
        return true;
    }

    function icoOpen() public view returns (bool open) {
         
        return ((now < (startTime + 4 weeks)) && !tokenReleased);
    }
    
    modifier released {
        require(tokenReleased);
        _;
    }
    
    modifier isOwner {
        require(msg.sender == fundsWallet);
        _;
    }

    function dividendsOwing(address _who) public view returns(uint256 owed) {
         
         
        if (totalDividends > lastDividends[_who]){
            uint256 newDividends = totalDividends - lastDividends[_who];
            return ((balances[_who] * newDividends) / totalSupply);
        } else {
            return 0;
        }
    }
    
    function updateDivs(address _who, uint256 _owing) internal {
        if (_owing > 0){
            if(_owing<=this.balance){
                _who.transfer(_owing);
            } else {
                _who.transfer(this.balance);
            }
        }
        lastDividends[_who] = totalDividends;
    }
    
    function remainingTokens() public view returns(uint256 remaining){
        return balances[fundsWallet];
    }
    
    function releaseToken() public isOwner {
        require(!tokenReleased);
        tokenReleased = true;
         
        totalSupply -= balances[fundsWallet];
        balances[fundsWallet] = 0;
    }
    
    function payDividends() public payable isOwner {
        totalDividends += msg.value;
    }
    
    function withdrawDividends() public {
        updateDivs(msg.sender,dividendsOwing(msg.sender));
    }
}