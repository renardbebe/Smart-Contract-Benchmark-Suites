 
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = SafeMath.sub(balances[account], amount, "ERC20: burn amount exceeds balance");
        totalSupply = SafeMath.sub(totalSupply, amount);
        circulatingSupply = SafeMath.sub(circulatingSupply, amount);
        emit Transfer(account, address(0), amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        if (balances[msg.sender] >= _value && _value > 0) {
            
            uint256 burnVal = _value / BurnRateDenominator;
            
            _burn(msg.sender, burnVal);
            
            balances[msg.sender] -= (_value - burnVal);
            balances[_to] += (_value - burnVal);
            emit Transfer(msg.sender, _to, (_value - burnVal));
            
            
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            
            uint256 burnVal = _value / BurnRateDenominator;
            
            _burn(_from, burnVal);
            
            balances[_to] += (_value - burnVal);
            balances[_from] -= (_value - burnVal);
            allowed[_from][msg.sender] -= (_value - burnVal);
            emit Transfer(_from, _to, (_value - burnVal));
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public circulatingSupply;
    uint256 public totalSupply;
    uint256 public BurnRateDenominator = 100;
}


contract SinguLottery is StandardToken {
    
     
    struct Entry { 
        address payable ticket;
        uint256 currentTotal;
        uint256 tokensSent;
    }
    
     
    string public name;                  
    string public symbol;            
    uint8 public decimals;                
    address payable public mostRecentWinner;
    uint256 public giveaway_total;
    
     
    uint256 public startTime;
    uint256 public endTime;
    uint256 public duration;
    
     
    address payable private owner;
    
     
    uint private hundMult;      
    uint private tenMult;       
    uint private oneMult;       
    uint private halfMult;      
    uint private tenthMult;     
    uint private fiveHundMult;  
    
    
     
    uint256 private storedSeed;
    Entry[] private entries;
    
    function () external payable {
         
        require(msg.sender != owner);  
        uint256 giveaway_value = calculateGiveaway(msg.value,0);
        
        require(giveaway_value > 0);
        entries.push(Entry(msg.sender, giveaway_total, SafeMath.div(giveaway_value, oneMult)));

        circulatingSupply = SafeMath.add(circulatingSupply, giveaway_value);
        
        giveaway_total = SafeMath.add(giveaway_total, SafeMath.div(giveaway_value, oneMult));

        
        balances[msg.sender] = SafeMath.add(balances[msg.sender], giveaway_value);
        balances[owner]      = SafeMath.sub(balances[owner], giveaway_value);
        
         
        storedSeed = storedSeed ^ uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.data, msg.sender)));

        owner.transfer(SafeMath.div(msg.value, 10));
        emit Transfer(owner, msg.sender, giveaway_value);
        
    }
 
    function calculateGiveaway(uint256 eth_val, uint256 giveout) private view returns (uint256 result) {
        uint256 multiplier;
        
        multiplier  = SafeMath.div(eth_val, hundMult);
        giveout     = SafeMath.add(giveout, SafeMath.mul(multiplier, 10000));
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, hundMult));
        
        multiplier  = SafeMath.div(eth_val, tenMult);
        giveout     = SafeMath.add(giveout, SafeMath.mul(multiplier, 666));
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, tenMult)); 
        
        multiplier  = SafeMath.div(eth_val, oneMult);
        giveout     = SafeMath.add(giveout, SafeMath.mul(multiplier, 35));
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, oneMult)); 
        
        multiplier  = SafeMath.div(eth_val, halfMult);
        giveout     = SafeMath.add(giveout, SafeMath.mul(multiplier, 20));
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, halfMult)); 
        
        multiplier  = SafeMath.div(eth_val, tenthMult);
        giveout     = SafeMath.add(giveout, SafeMath.mul(multiplier, 3));
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, tenthMult)); 
        
        multiplier  = SafeMath.div(eth_val, fiveHundMult);
        giveout     = SafeMath.add(giveout, multiplier);
        eth_val     = SafeMath.sub(eth_val, SafeMath.mul(multiplier, fiveHundMult)); 
        
        return SafeMath.mul(giveout, oneMult);
    }
    
    function enterHouseSeedAndStartGiveaway(string memory _seed) public{
        require(msg.sender == owner);
        storedSeed = storedSeed ^ uint256(keccak256(abi.encodePacked(_seed)));
        triggerGiveaway();

    }

    function triggerGiveaway() private {
        require (block.timestamp > endTime && block.timestamp > startTime);
        mostRecentWinner = findWinner();
        mostRecentWinner.transfer(address(this).balance);
        entries.length = 0;
        startTime = block.timestamp;
        endTime = startTime + duration;
        giveaway_total = 0;
    }
    
    function findWinner() private view returns (address payable winner){
        uint256 randomNumber = storedSeed % giveaway_total;
    
        for (uint i = 0; i < entries.length; i++){
            if(randomNumber > entries[i].currentTotal && randomNumber <= entries[i].tokensSent + entries[i].currentTotal) return entries[i].ticket;
        }
        
    }

    constructor() SinguLottery (
        ) public {      
        totalSupply       = 50000000000000000000000000; 
        circulatingSupply =  5000000000000000000000000;
        
        balances[msg.sender] = totalSupply - circulatingSupply;        
        
         
        name     = "SinguLottery";                            
        decimals = 18;                                  
        symbol   = "SLY";                                
        owner    = msg.sender;
        
         
        emit Transfer(owner, address(0x5357721aa06f21587b0c0D59734D57Be176C220f), 2500000000000000000000000);  
        emit Transfer(owner, address(0x0704Ff94E4dd0becac849139608621f869Cf01Ed), 650000000000000000000000);   
        emit Transfer(owner, address(0x832B4718505f27e3Ee5Ad07cD5d369ed2087c3AC), 300000000000000000000000);   
        emit Transfer(owner, address(0x3532F06e749Ed7BAC22bA4510d90063127D50220), 300000000000000000000000);   
        emit Transfer(owner, address(0xC755318832F3F5509a66E6506A9DfcA64e8F2a6A), 300000000000000000000000);   
        emit Transfer(owner, address(0xD26B07DfE5482c8BAb5EaFc0BF411f9c207710b0), 100000000000000000000000);   
        emit Transfer(owner, address(0xa9Fc957bba450bFe7B57CF07098e59b69F390892), 85000000000000000000000);    
        emit Transfer(owner, address(0x8859e56693c8A8292a38acDEcCD97b9bc2307e43), 85000000000000000000000);    
        emit Transfer(owner, address(0x9251dB9Bbeba1431F94c52Da83cFdAfeaD800bf3), 85000000000000000000000);    
        emit Transfer(owner, address(0xAF08BF99a98D09118299A80A5Ce0a009B03B6B4d), 85000000000000000000000);    
        emit Transfer(owner, address(0xCCf9e8CdA151b6d314201E9da65697B0eBc8A381), 85000000000000000000000);    
        emit Transfer(owner, address(0x5Dc178505FaabA7302e48e9Df22C74C9Dd63ecf1), 85000000000000000000000);    
        emit Transfer(owner, address(0xdA503fb4e92b78Fd399B922836C9b1F94321802B), 85000000000000000000000);    
        emit Transfer(owner, address(0xa9D0934123cD23Eff65ac17A52FD3197afAb8860), 85000000000000000000000);    
        emit Transfer(owner, address(0x32409B1C6dE73136f6e4C4315569197Ea425D85A), 85000000000000000000000);    
        emit Transfer(owner, address(0x8852De0be6eAFF06AC4B7Ca11DcAf4873CA609Dc), 85000000000000000000000);    
        
        
        balances[address(0x5357721aa06f21587b0c0D59734D57Be176C220f)] = 2500000000000000000000000;   
        balances[address(0x0704Ff94E4dd0becac849139608621f869Cf01Ed)] =  650000000000000000000000;   
        balances[address(0x832B4718505f27e3Ee5Ad07cD5d369ed2087c3AC)] =  300000000000000000000000;   
        balances[address(0x3532F06e749Ed7BAC22bA4510d90063127D50220)] =  300000000000000000000000;   
        balances[address(0xC755318832F3F5509a66E6506A9DfcA64e8F2a6A)] =  300000000000000000000000;   
        balances[address(0xD26B07DfE5482c8BAb5EaFc0BF411f9c207710b0)] =  100000000000000000000000;   
        balances[address(0xa9Fc957bba450bFe7B57CF07098e59b69F390892)] =   85000000000000000000000;   
        balances[address(0x8859e56693c8A8292a38acDEcCD97b9bc2307e43)] =   85000000000000000000000;   
        balances[address(0x9251dB9Bbeba1431F94c52Da83cFdAfeaD800bf3)] =   85000000000000000000000;   
        balances[address(0xAF08BF99a98D09118299A80A5Ce0a009B03B6B4d)] =   85000000000000000000000;   
        balances[address(0xCCf9e8CdA151b6d314201E9da65697B0eBc8A381)] =   85000000000000000000000;   
        balances[address(0x5Dc178505FaabA7302e48e9Df22C74C9Dd63ecf1)] =   85000000000000000000000;   
        balances[address(0xdA503fb4e92b78Fd399B922836C9b1F94321802B)] =   85000000000000000000000;   
        balances[address(0xa9D0934123cD23Eff65ac17A52FD3197afAb8860)] =   85000000000000000000000;   
        balances[address(0x32409B1C6dE73136f6e4C4315569197Ea425D85A)] =   85000000000000000000000;   
        balances[address(0x8852De0be6eAFF06AC4B7Ca11DcAf4873CA609Dc)] =   85000000000000000000000;   

        
         
        hundMult     = 10**20;
        tenMult      = 10**19;
        oneMult      = 10**18;
        halfMult     = (10**17) * 5;
        tenthMult    = 10**17;
        fiveHundMult = (10**16) * 5;
        
        startTime = block.timestamp;
        
        duration = 60 * 60 * 24 * 7;  
        
        endTime = startTime + duration;
        storedSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }
}