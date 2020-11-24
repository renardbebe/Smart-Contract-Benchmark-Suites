 

pragma solidity ^0.4.25;

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
}

contract AltcoinToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NSE is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "Neo Smart Energy";
    string public constant symbol = "NSE";
    uint public constant decimals = 8;
    
    uint256 public totalSupply = 50000000e8;
    uint256 public totalDistributed = 0;   
    
    uint256 public alocationPrivateSale = 2000000e8;   
    uint256 public alocationBounty = 2000000e8; 
    uint256 public alocationAdvisor = 1000000e8; 
    uint256 public alocationRnD = 4000000e8; 
    uint256 public alocationPromotion = 2000000e8; 
    uint256 public alocationDeveloper = 22000000e8;   
    
    uint256 public tokensPerEth =  31000000;  
    uint256 public tokensPer2Eth = 35000000;  
    uint256 public tokensPer3Eth = 39000000;
    uint256 public startPase = 0;
    
    uint256 public maxPhase1 = 3000000e8;
    uint256 public maxPhase2 = 5000000e8;
    uint256 public maxPhase3 = 9000000e8;
    
    uint256 public statusPhase = 0; 
    uint256 public soldPhase1 = 0;
    uint256 public soldPhase2 = 0;
    uint256 public soldPhase3 = 0;
    
    uint256 public pase1 = 0;
    uint256 public pase2 = 0;
    uint256 public pase3 = 0; 

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event StartPaseUpdated(uint256 _time);
    event PriceICOSet(uint _phase,uint256 _tokensPerEth); 
    event MaxICOSet(uint _phase,uint256 _maxPhase);
    event DateICOSet(uint _phase,uint256 _datePhase);
    event StatusICOSet(uint _status);

    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        
        uint256 devTokens = (alocationDeveloper + alocationPrivateSale + alocationBounty + alocationAdvisor + alocationRnD + alocationPromotion);
        distr(owner, devTokens); 
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

    function doAirdrop(address _participant, uint _amount) internal {

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

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }
    
    function () external payable {
        getTokens();
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 sold = 0;
    

        require( msg.value > 0 );
        require( statusPhase == 1 );

        require( now > startPase && now < pase3);
        
        if(now > startPase && now < pase1 && soldPhase1 <= maxPhase1 ){
            tokens = msg.value / tokensPerEth;
        }else if(now >= pase1 && now < pase2 && soldPhase2 <= maxPhase2 ){
            tokens = msg.value / tokensPer2Eth;
        }else if(now >= pase2 && now < pase3 && soldPhase3 <= maxPhase3 ){
            tokens = msg.value / tokensPer3Eth;
        }
                
        address investor = msg.sender;
        
        if (tokens > 0) {
            if(now > startPase && now <= pase1 && soldPhase1 <= maxPhase1 ){
                sold = soldPhase1 + tokens;
                require(sold + tokens <= maxPhase1);
                soldPhase1 += tokens;
            }else if(now > pase1 && now <= pase2 && soldPhase2 <= maxPhase2 ){
                sold = soldPhase2 + tokens;
                require(sold + tokens <= maxPhase2);
                soldPhase2 += tokens;
            }else if(now > pase2 && now <= pase3 && soldPhase3 <= maxPhase3 ){
                sold = soldPhase3 + tokens;
                require(sold + tokens <= maxPhase3);
                soldPhase3 += tokens;
            }
            
            distr(investor, tokens);
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }


    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        AltcoinToken t = AltcoinToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawAltcoinTokens(address _tokenContract) onlyOwner public returns (bool) {
        AltcoinToken token = AltcoinToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    } 
    
    
    function setPriceICO(uint _phase,uint256 _tokensPerEth) public onlyOwner {          
        if(_phase == 1){ 
            tokensPerEth = _tokensPerEth;
        }else if(_phase == 2){ 
            tokensPer2Eth = _tokensPerEth;
        }else if(_phase == 3){  
            tokensPer3Eth = _tokensPerEth;
        }      
        emit PriceICOSet(_phase,_tokensPerEth);
    }  
    
    function setMaxICO(uint _phase,uint256 _maxPhase1) public onlyOwner {        
        if(_phase == 1){ 
            maxPhase1 = _maxPhase1;
        }else if(_phase == 2){ 
            maxPhase2 = _maxPhase1;
        }else if(_phase == 3){  
            maxPhase3 = _maxPhase1;
        }
        emit MaxICOSet(_phase,_maxPhase1);
    }  
    
    function setDateICO(uint _phase,uint256 _maxPhase1) public onlyOwner {     
        if(_phase == 1){ 
            pase1 = _maxPhase1;
        }else if(_phase == 2){ 
            pase2 = _maxPhase1;
        }else if(_phase == 3){  
            pase3 = _maxPhase1;
        }
        emit DateICOSet(_phase,_maxPhase1);
    }  
    function setStatusICO(uint _status) public onlyOwner {  
        statusPhase = _status;
        emit StatusICOSet(_status);
    } 

}