 

pragma solidity ^0.4.15;

 

 

 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.11;

 
library BTC {
     
     
    function parseVarInt(bytes txBytes, uint pos) returns (uint, uint) {
         
        var ibit = uint8(txBytes[pos]);
        pos += 1;   

        if (ibit < 0xfd) {
            return (ibit, pos);
        } else if (ibit == 0xfd) {
            return (getBytesLE(txBytes, pos, 16), pos + 2);
        } else if (ibit == 0xfe) {
            return (getBytesLE(txBytes, pos, 32), pos + 4);
        } else if (ibit == 0xff) {
            return (getBytesLE(txBytes, pos, 64), pos + 8);
        }
    }
     
    function getBytesLE(bytes data, uint pos, uint bits) returns (uint) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return uint16(data[pos])
                 + uint16(data[pos + 1]) * 2 ** 8;
        } else if (bits == 32) {
            return uint32(data[pos])
                 + uint32(data[pos + 1]) * 2 ** 8
                 + uint32(data[pos + 2]) * 2 ** 16
                 + uint32(data[pos + 3]) * 2 ** 24;
        } else if (bits == 64) {
            return uint64(data[pos])
                 + uint64(data[pos + 1]) * 2 ** 8
                 + uint64(data[pos + 2]) * 2 ** 16
                 + uint64(data[pos + 3]) * 2 ** 24
                 + uint64(data[pos + 4]) * 2 ** 32
                 + uint64(data[pos + 5]) * 2 ** 40
                 + uint64(data[pos + 6]) * 2 ** 48
                 + uint64(data[pos + 7]) * 2 ** 56;
        }
    }
     
     
    function getFirstTwoOutputs(bytes txBytes)
             returns (uint, bytes20, uint, bytes20)
    {
        uint pos;
        uint[] memory input_script_lens = new uint[](2);
        uint[] memory output_script_lens = new uint[](2);
        uint[] memory script_starts = new uint[](2);
        uint[] memory output_values = new uint[](2);
        bytes20[] memory output_addresses = new bytes20[](2);

        pos = 4;   

        (input_script_lens, pos) = scanInputs(txBytes, pos, 0);

        (output_values, script_starts, output_script_lens, pos) = scanOutputs(txBytes, pos, 2);

        for (uint i = 0; i < 2; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            output_addresses[i] = pkhash;
        }

        return (output_values[0], output_addresses[0],
                output_values[1], output_addresses[1]);
    }
     
     
         
     
    function checkValueSent(bytes txBytes, bytes20 btcAddress, uint value)
             returns (bool,uint)
    {
        uint pos = 4;   
        (, pos) = scanInputs(txBytes, pos, 0);   

         
        var (output_values, script_starts, output_script_lens,) = scanOutputs(txBytes, pos, 0);

         
        for (uint i = 0; i < output_values.length; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            if (pkhash == btcAddress && output_values[i] >= value) {
                return (true,output_values[i]);
            }
        }
    }
     
     
     
     
     
    function scanInputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint)
    {
        uint n_inputs;
        uint halt;
        uint script_len;

        (n_inputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_inputs) {
            halt = n_inputs;
        } else {
            halt = stop;
        }

        uint[] memory script_lens = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            pos += 36;   
            (script_len, pos) = parseVarInt(txBytes, pos);
            script_lens[i] = script_len;
            pos += script_len + 4;   
        }

        return (script_lens, pos);
    }
     
     
     
     
     
    function scanOutputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint[], uint[], uint)
    {
        uint n_outputs;
        uint halt;
        uint script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_outputs) {
            halt = n_outputs;
        } else {
            halt = stop;
        }

        uint[] memory script_starts = new uint[](halt);
        uint[] memory script_lens = new uint[](halt);
        uint[] memory output_values = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            output_values[i] = getBytesLE(txBytes, pos, 64);
            pos += 8;

            (script_len, pos) = parseVarInt(txBytes, pos);
            script_starts[i] = pos;
            script_lens[i] = script_len;
            pos += script_len;
        }

        return (output_values, script_starts, script_lens, pos);
    }
     
    function sliceBytes20(bytes data, uint start) returns (bytes20) {
        uint160 slice = 0;
        for (uint160 i = 0; i < 20; i++) {
            slice += uint160(data[i + start]) << (8 * (19 - i));
        }
        return bytes20(slice);
    }
     
     
    function isP2PKH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 25)            
            && (txBytes[pos] == 0x76)        
            && (txBytes[pos + 1] == 0xa9)    
            && (txBytes[pos + 2] == 0x14)    
            && (txBytes[pos + 23] == 0x88)   
            && (txBytes[pos + 24] == 0xac);  
    }
     
     
    function isP2SH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 23)            
            && (txBytes[pos + 0] == 0xa9)    
            && (txBytes[pos + 1] == 0x14)    
            && (txBytes[pos + 22] == 0x87);  
    }
     
     
     
    function parseOutputScript(bytes txBytes, uint pos, uint script_len)
             returns (bytes20)
    {
        if (isP2PKH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 3);
        } else if (isP2SH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 2);
        } else {
            return;
        }
    }
}

 

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

 

 

contract Pausable is Ownable {
  bool public stopped;

  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }

  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }

   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

 

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

 

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
        } else {
            return false;
        }
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


}

 

contract Utils{

	 

	modifier greaterThanZero(uint256 _value){
		require(_value>0);
		_;
	}

	 

	modifier validAddress(address _add){
		require(_add!=0x0);
		_;
	}
}

 

contract Crowdsale is StandardToken, Pausable, SafeMath, Utils{
	string public constant name = "Mudra";
	string public constant symbol = "MUDRA";
	uint256 public constant decimals = 18;
	string public version = "1.0";
	bool public tradingStarted = false;

     
   modifier hasStartedTrading() {
   	require(tradingStarted);
   	_;
   }
   
   function startTrading() onlyOwner() {
   	tradingStarted = true;
   }

   function transfer(address _to, uint _value) hasStartedTrading returns (bool success) {super.transfer(_to, _value);}

   function transferFrom(address _from, address _to, uint _value) hasStartedTrading returns (bool success) {super.transferFrom(_from, _to, _value);}

   enum State{
   	Inactive,
   	Funding,
   	Success,
   	Failure
   }

   uint256 public investmentETH;
   uint256 public investmentBTC;
   mapping(uint256 => bool) transactionsClaimed;
   uint256 public initialSupply;
   address wallet;
   uint256 public constant _totalSupply = 100 * (10**6) * 10 ** decimals;  
   uint256 public fundingStartBlock;  
   uint256 public constant minBtcValue = 10000;  
   uint256 public tokensPerEther = 450;  
   uint256 public tokensPerBTC = 140 * 10 ** 10 * 10 ** 2;  
   uint256 public constant tokenCreationMax = 10 * (10**6) * 10 ** decimals;  
   address[] public investors;

    
   function investorsCount() constant external returns(uint) { return investors.length; }

   function Crowdsale(uint256 _fundingStartBlock, address _owner, address _wallet){
      owner = _owner;
      fundingStartBlock =_fundingStartBlock;
      totalSupply = _totalSupply;
      initialSupply = 0;
      wallet = _wallet;

       
      if (
        tokensPerEther == 0
        || tokensPerBTC == 0
        || owner == 0x0
        || wallet == 0x0
        || fundingStartBlock == 0
        || totalSupply == 0
        || tokenCreationMax == 0
        || fundingStartBlock <= block.number)
      throw;

   }

    
    
    
    
    
   function getState() constant public returns(State){
   	 
   	if(block.number<fundingStartBlock) return State.Inactive;
   	else if(block.number>fundingStartBlock && initialSupply<tokenCreationMax) return State.Funding;
   	else if (initialSupply >= tokenCreationMax) return State.Success;
   	else return State.Failure;
   }

    
   function getTokens(address addr) public returns(uint256){
   	return balances[addr];
   }

    
   function getStateFunding() public returns (uint256){
   	 
   	if(block.number<fundingStartBlock + 180000) return 20;  
   	else if(block.number>=fundingStartBlock+ 180001 && block.number<fundingStartBlock + 270000) return 10;  
   	else if(block.number>=fundingStartBlock + 270001 && block.number<fundingStartBlock + 36000) return 5;  
   	else return 0;
   }
    
    
   function calNewTokens(uint256 tokens) returns (uint256){
   	uint256 disc = getStateFunding();
   	tokens = safeAdd(tokens,safeDiv(safeMul(tokens,disc),100));
   	return tokens;
   }

   function() external payable stopInEmergency{
   	 
   	if(getState() == State.Success) throw;
   	if (msg.value == 0) throw;
   	uint256 newCreatedTokens = safeMul(msg.value,tokensPerEther);
   	newCreatedTokens = calNewTokens(newCreatedTokens);
   	 
   	initialSupply = safeAdd(initialSupply,newCreatedTokens);
   	if(initialSupply>tokenCreationMax) throw;
      if (balances[msg.sender] == 0) investors.push(msg.sender);
      investmentETH += msg.value;
      balances[msg.sender] = safeAdd(balances[msg.sender],newCreatedTokens);
       
      if(!wallet.send(msg.value)) throw;
   }


    
    
   function tokenAssignExchange(address addr,uint256 val)
   external
   stopInEmergency
   onlyOwner()
   {
   	if(getState() == State.Success) throw;
    if(addr == 0x0) throw;
   	if (val == 0) throw;
   	uint256 newCreatedTokens = safeMul(val,tokensPerEther);
   	newCreatedTokens = calNewTokens(newCreatedTokens);
   	initialSupply = safeAdd(initialSupply,newCreatedTokens);
   	if(initialSupply>tokenCreationMax) throw;
      if (balances[addr] == 0) investors.push(addr);
      investmentETH += val;
      balances[addr] = safeAdd(balances[addr],newCreatedTokens);
   }

    
   function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr)
   external
   stopInEmergency
   onlyOwner()
   returns (uint)
   {
   	if(getState() == State.Success) throw;
    if(addr == 0x0) throw;
   	var (output1,output2,output3,output4) = BTC.getFirstTwoOutputs(txn);
      if(transactionsClaimed[txHash]) throw;
      var (a,b) = BTC.checkValueSent(txn,btcaddr,minBtcValue);
      if(a){
         transactionsClaimed[txHash] = true;
         uint256 newCreatedTokens = safeMul(b,tokensPerBTC);
          
         newCreatedTokens = calNewTokens(newCreatedTokens);
         initialSupply = safeAdd(initialSupply,newCreatedTokens);
          
         if(initialSupply>tokenCreationMax) throw;
         if (balances[addr] == 0) investors.push(addr);
         investmentBTC += b;
         balances[addr] = safeAdd(balances[addr],newCreatedTokens);
         return 1;
      }
      else return 0;
   }

    
   function changeExchangeRate(uint256 eth, uint256 btc)
   external
   onlyOwner()
   {
     if(eth == 0 || btc == 0) throw;
     tokensPerEther = eth;
     tokensPerBTC = btc;
  }

   
   
   
  function blacklist(address addr)
  external
  onlyOwner()
  {
     balances[addr] = 0;
  }

}