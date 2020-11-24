 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Sales{

	enum ICOSaleState{
	    PrivateSale,
	    PreSale,
	    PreICO,
	    PublicICO
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


 
contract SMTToken is Token,Ownable,Sales {
    string public constant name = "Sun Money Token";
    string public constant symbol = "SMT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    uint public valueToBeSent = 1;
     
    address personMakingTx;
     
     
    address public addr1;
     
    address public txorigin;

     
    bool isTesting;
     
    bytes32 testname;
    address finalOwner;
    bool public finalizedPublicICO = false;
    bool public finalizedPreICO = false;

    uint256 public SMTfundAfterPreICO;
    uint256 public ethraised;
    uint256 public btcraised;

    bool public istransferAllowed;

    uint256 public constant SMTfund = 10 * (10**6) * 10**decimals; 
    uint256 public fundingStartBlock;  
    uint256 public fundingEndBlock;  
    uint256 public  tokensPerEther = 150;  
    uint256 public  tokensPerBTC = 22*150*(10**10);
    uint256 public tokenCreationMax= 72* (10**5) * 10**decimals;  
    mapping (address => bool) ownership;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

     
    function SMTToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        totalSupply = SMTfund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }


    ICOSaleState public salestate = ICOSaleState.PrivateSale;

     
     

     
    event stateChange(ICOSaleState state);

     
    function setState(ICOSaleState state)  returns (bool){
    if(!ownership[msg.sender]) throw;
    salestate = state;
    stateChange(salestate);
    return true;
    }

     
    function getState() returns (ICOSaleState) {
    return salestate;

    }



    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
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

    function addToBalances(address _person,uint256 value) {
        if(!ownership[msg.sender]) throw;
        balances[_person] = SafeMath.add(balances[_person],value);

    }

    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      if(!istransferAllowed) throw;
      return allowed[_owner][_spender];
    }

    function increaseEthRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        ethraised+=value;
    }

    function increaseBTCRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        btcraised+=value;
    }




    function finalizePreICO(uint256 value) returns(bool){
        if(!ownership[msg.sender]) throw;
        finalizedPreICO = true;
        SMTfundAfterPreICO =value;
        return true;
    }


    function finalizePublicICO() returns(bool) {
        if(!ownership[msg.sender]) throw;
        finalizedPublicICO = true;
        istransferAllowed = true;
        return true;
    }


    function isValid() returns(bool){
        if(block.number>=fundingStartBlock && block.number<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
    }

     

    function() payable{
        throw;
    }
}








 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier stopInEmergency {
    if (paused) {
      throw;
    }
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 

 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



 
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





 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract PricingStrategy{

	 
	function baseDiscounts(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=1*10**18){
			 return 40;
			}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=5*10**17){
				return 30;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=45*10**5){
				 return 40;
				}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=225*10**4){
					return 30;
				}else{
					return 0;
				}
			}	
	}

	 
	function volumeDiscounts(uint256 contribution,string types) returns (uint256){
		 
		 
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(contribution>=3*10**18 && contribution<10*10**18){
				return 0;
			}else if(contribution>=10*10**18 && contribution<20*10**18){
				return 5;
			}else if(contribution>=20*10**18){
				return 10;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(contribution>=3*45*10**5 && contribution<10*45*10**5){
					return 0;
				}else if(contribution>=10*45*10**5 && contribution<20*45*10**5){
					return 5;
				}else if(contribution>=20*45*10**5){
					return 10;
				}else{
					return 0;
				}
			}

	}

	 
	 
	function totalDiscount(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		uint256 basediscount = baseDiscounts(currentsupply,contribution,types);
		uint256 volumediscount = volumeDiscounts(contribution,types);
		uint256 totaldiscount = basediscount+volumediscount;
		return totaldiscount;
	}
}



contract PreICO is Ownable,Pausable, Utils,PricingStrategy,Sales{

	SMTToken token;
	uint256 public tokensPerBTC;
	uint public tokensPerEther;
	uint256 public initialSupplyPrivateSale;
	uint256 public initialSupplyPreSale;
	uint256 public SMTfundAfterPreICO;
	uint256 public initialSupplyPublicPreICO;
	uint256 public currentSupply;
	uint256 public fundingStartBlock;
	uint256 public fundingEndBlock;
	uint256 public SMTfund;
	uint256 public tokenCreationMaxPreICO = 15* (10**5) * 10**18;
	uint256 public tokenCreationMaxPrivateSale = 15*(10**5) * (10**18);
	 
	uint256 public team = 1*(10**6)*(10**18);
	 
	uint256 public reserve = 1*(10**6)*(10**18);
	 
	uint256 public mentors = 5*(10**5)*10**18;
	 
	uint256 public bounty = 3*(10**5)*10**18;
	 

	uint256 totalsend = team+reserve+bounty+mentors;
	address public addressPeople = 0xea0f17CA7C3e371af30EFE8CbA0e646374552e8B;

	address public ownerAddr = 0x4cA09B312F23b390450D902B21c7869AA64877E3;
	 
	uint256 public numberOfBackers;
	 
	 
	 
	mapping(uint256 => bool) transactionsClaimed;
	uint256 public valueToBeSent;

	 
   function PreICO(address tokenAddress){
		 
		token = SMTToken(tokenAddress);
		tokensPerEther = token.tokensPerEther();
		tokensPerBTC = token.tokensPerBTC();
		valueToBeSent = token.valueToBeSent();
		SMTfund = token.SMTfund();
	}
	
	 
    function sendFunds() onlyOwner{
        token.addToBalances(addressPeople,totalsend);
    }

	 
	 
	function calNewTokens(uint256 contribution,string types) returns (uint256){
		uint256 disc = totalDiscount(currentSupply,contribution,types);
		uint256 CreatedTokens;
		if(keccak256(types)==keccak256("ethereum")) CreatedTokens = SafeMath.mul(contribution,tokensPerEther);
		else if(keccak256(types)==keccak256("bitcoin"))  CreatedTokens = SafeMath.mul(contribution,tokensPerBTC);
		uint256 tokens = SafeMath.add(CreatedTokens,SafeMath.div(SafeMath.mul(CreatedTokens,disc),100));
		return tokens;
	}
	 
	function() external payable stopInEmergency{
        if(token.getState()==ICOSaleState.PublicICO) throw;
        bool isfinalized = token.finalizedPreICO();
        bool isValid = token.isValid();
        if(isfinalized) throw;
        if(!isValid) throw;
        if (msg.value == 0) throw;
        uint256 newCreatedTokens;
         
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if((msg.value) < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(msg.sender,SafeMath.add(finalTokens,consumed));
        	 if(!ownerAddr.send(msg.value))throw;
        	  token.increaseEthRaised(msg.value);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(msg.sender,newCreatedTokens);
            	if(!ownerAddr.send(msg.value))throw;
            	token.increaseEthRaised(msg.value);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(msg.sender,newCreatedTokens);
        	if(!ownerAddr.send(msg.value))throw;
        	token.increaseEthRaised(msg.value);
        }

	}

	 
	 
	function tokenAssignExchange(address addr,uint256 val,uint256 txnHash) public onlyOwner {
	    
	  if (val == 0) throw;
	  if(token.getState()==ICOSaleState.PublicICO) throw;
	  if(transactionsClaimed[txnHash]) throw;
	  bool isfinalized = token.finalizedPreICO();
	  if(isfinalized) throw;
	  bool isValid = token.isValid();
	  if(!isValid) throw;
	  uint256 newCreatedTokens;
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(val < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseEthRaised(val);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseEthRaised(val);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseEthRaised(val);
        }
	}

	 
	 
	function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr) onlyOwner returns (uint)
	{
		bool valueSent;
		bool isValid = token.isValid();
		if(!isValid) throw;
		 
		 
		if(!transactionsClaimed[txHash]){
			var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
			if(a){
				valueSent = true;
				transactionsClaimed[txHash] = true;
				uint256 newCreatedTokens;
				  
            if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(b < 45*10**5) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseBTCRaised(b);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseBTCRaised(b);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 225*10**4) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseBTCRaised(b);
         }
		return 1;
			}
		}
		else{
		    throw;
		}
	}

	function finalizePreICO() public onlyOwner{
		uint256 val = currentSupply;
		token.finalizePreICO(val);
	}

	function switchState() internal  {
		 token.setState(ICOSaleState.PreICO);
		
	}
	

	

}