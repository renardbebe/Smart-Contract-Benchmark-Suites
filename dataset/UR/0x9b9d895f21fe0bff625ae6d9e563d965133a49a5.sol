 

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
	    PublicSale,
	    Success,
	    Failed
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


 
contract GACToken is Token,Ownable,Sales {
    string public constant name = "Gladage Care Token";
    string public constant symbol = "GAC";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    uint public valueToBeSent = 1;

    bool public finalizedICO = false;

    uint256 public ethraised;
    uint256 public btcraised;
    uint256 public usdraised;

    bool public istransferAllowed;

    uint256 public constant GACFund = 5 * (10**8) * 10**decimals; 
    uint256 public fundingStartBlock;  
    uint256 public fundingEndBlock;  
    uint256 public tokenCreationMax= 275 * (10**6) * 10**decimals; 
    mapping (address => bool) ownership;
    uint256 public minCapUSD = 2000000;
    uint256 public maxCapUSD = 20000000;


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

    function burnTokens(uint256 _value) public{
        require(balances[msg.sender]>=_value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender],_value);
        totalSupply =SafeMath.sub(totalSupply,_value);
    }


     
    function GACToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        totalSupply = GACFund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }

     
    function changeEndBlock(uint256 _newFundingEndBlock) onlyOwner{
        fundingEndBlock = _newFundingEndBlock;
    }

     
    function changeStartBlock(uint256 _newFundingStartBlock) onlyOwner{
        fundingStartBlock = _newFundingStartBlock;
    }

     
     
    function changeMinCapUSD(uint256 _newMinCap) onlyOwner{
        minCapUSD = _newMinCap;
    }

     
    function changeMaxCapUSD(uint256 _newMaxCap) onlyOwner{
        maxCapUSD = _newMaxCap;
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
        Transfer(address(this), _person, value);
    }

    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
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

    function increaseUSDRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        usdraised+=value;
    }

    function finalizeICO(){
        if(!ownership[msg.sender]) throw;
         
         
        if(usdraised<minCapUSD) throw;
        finalizedICO = true;
        istransferAllowed = true;
    }

    function enableTransfers() public onlyOwner{
        istransferAllowed = true;
    }

    function disableTransfers() public onlyOwner{
        istransferAllowed = false;
    }

     
    function finalizeICOOwner() onlyOwner{
        finalizedICO = true;
        istransferAllowed = true;
    }

    function isValid() returns(bool){
        if(now>=fundingStartBlock && now<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
        if(usdraised>maxCapUSD) throw;
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




contract PricingStrategy is Ownable{
    uint public ETHUSD=580;
    uint public BTCUSD=9000;
    uint256 public exchangeRate;
    bool public called;
    
    function getLatest(uint btcusd,uint ethusd) onlyOwner{
        ETHUSD = ethusd;
        BTCUSD = btcusd;
    }


    uint256 public bonuspercentageprivate = 50;
    uint256 public bonuspercentagepresale = 25;
    uint256 public bonuspercentagepublic  = 0;

    function changeprivatebonus(uint256 _value) public onlyOwner{
        bonuspercentageprivate = _value;
    }

    function changepublicbonus(uint256 _value) public onlyOwner{
        bonuspercentagepresale = _value;
    }

    function changepresalebonus(uint256 _value) public onlyOwner{
        bonuspercentagepublic = _value;
    }

    uint256 public mincontribprivatesale = 15000;
    uint256 public mincontribpresale = 1000;
    uint256 public mincontribpublicsale = 0;

    function changeminprivatesale(uint256 _value) public onlyOwner{
        mincontribprivatesale = _value;
    }

    function changeminpresale(uint256 _value) public onlyOwner{
        mincontribpresale = _value;
    }

    function changeminpublicsale(uint256 _value) public onlyOwner{
        mincontribpublicsale = _value;
    }


     
    event logval(uint256 s);

    function totalDiscount(Sales.ICOSaleState state,uint256 contribution,string types) returns (uint256,uint256){
        uint256 valueInUSD;
        if(keccak256(types)==keccak256("ethereum")){
            if(ETHUSD==0) throw;
            valueInUSD = (ETHUSD*contribution)/1000000000000000000;
            logval(valueInUSD);

        }else if(keccak256(types)==keccak256("bitcoin")){
            if(BTCUSD==0) throw;
            valueInUSD = (BTCUSD*contribution)/100000000;
            logval(valueInUSD);

        }
        if(state==Sales.ICOSaleState.PrivateSale){
            if(valueInUSD<mincontribprivatesale) throw;
            return (bonuspercentageprivate,valueInUSD);
        }else if(state==Sales.ICOSaleState.PreSale){
            if(valueInUSD<mincontribpresale) throw;
            return (bonuspercentagepresale,valueInUSD);
        }else if(state==Sales.ICOSaleState.PublicSale){
            if(valueInUSD>=mincontribpublicsale) throw;
            return (bonuspercentagepublic,valueInUSD);
        }
        else{
            return (0,0);
        }
    }
    
    function() payable{
        
    }
}


 

 



contract NewTokenSale is Ownable,Pausable, Utils,Sales{

    GACToken token;
    bool fundssent;
    uint256 public tokensPerUSD;
    uint256 public currentSupply = 634585000000000000000000;
    PricingStrategy pricingstrategy;
    uint256 public tokenCreationMax = 275 * (10**6) * 10**18;

     
    address public ownerAddr =0xB0583785f27B7f87535B4c574D3B30928aD3A7eb ;  

     
    address public distributorAddress = 0x5377209111cBe0cfeeaA54c4C28465cbf81D5601;

     
    uint256 public maxPrivateSale = 150 * (10**6) * (10**18);
     
    uint256 public maxPreSale = 100 * (10**6) * (10**18);

     
    uint256 public maxPublicSale = 20* (10**6) * (10**18);

     
    uint256 public endprivate = 1525219200;  
    uint256 public endpresale = 1527724800; 
     
    uint256 public currentPrivateSale = 630585000000000000000000;
    uint256 public currentPreSale = 4000000000000000000000;
    uint256 public currentPublicSale ; 


     
    uint256  public numberOfBackers;

    mapping(uint256 => bool) transactionsClaimed;
    uint256 public valueToBeSent;
    uint public investorCount;

    struct balanceStruct{
        uint256 value;
        bool tokenstransferred;
    }

    mapping(address => balanceStruct) public balances;
    address[] public balancesArr;

     
    event logaddr(address addr);

     
    function getBalance(address addr) public view returns(uint256) {
        return balances[addr].value;
    }

     
    function addToBalances(address addr, uint256 tokenValue) internal{
        balances[addr].value = SafeMath.add(balances[addr].value,tokenValue);
        bool found;
        for(uint i=0;i<balancesArr.length;i++){
            if(balancesArr[i]==addr){
                found = true;
            }
        }
        if(!found){
            balancesArr.push(addr);
        }
    }

     
    function alottMainSaleToken(address[] arr) public {
        require(msg.sender == distributorAddress);
        for(uint i=0;i<arr.length;i++){
            if(checkExistsInArray(arr[i])){
            if(!balances[arr[i]].tokenstransferred){
                balances[arr[i]].tokenstransferred = true;
                token.addToBalances(arr[i], balances[arr[i]].value);
            }
        }
        }
    }

    function checkExistsInArray(address addr) internal returns (bool) {
        for(uint i=0;i<balancesArr.length;i++){
            if(balancesArr[i]==addr){
                return true;
            }
        }
        return false;
    }

     
   function NewTokenSale(address tokenAddress,address strategy){
         
        token = GACToken(tokenAddress);
        tokensPerUSD = 10 * 10 ** 18;
        valueToBeSent = token.valueToBeSent();
        pricingstrategy = PricingStrategy(strategy);
    }

     
    function() external payable stopInEmergency{
        require(token.isValid());
        require(msg.value>0);
        ICOSaleState currentState = getStateFunding();
        require(currentState!=ICOSaleState.Failed);
        require(currentState!=ICOSaleState.Success);
        var (discount,usd) = pricingstrategy.totalDiscount(currentState,msg.value,"ethereum");
        uint256 tokens = usd*tokensPerUSD;
        uint256 totalTokens = SafeMath.add(tokens,SafeMath.div(SafeMath.mul(tokens,discount),100));
        if(currentState==ICOSaleState.PrivateSale){
            require(SafeMath.add(currentPrivateSale,totalTokens)<=maxPrivateSale);
            currentPrivateSale = SafeMath.add(currentPrivateSale,totalTokens);
        }else if(currentState==ICOSaleState.PreSale){
            require(SafeMath.add(currentPreSale,totalTokens)<=maxPreSale);
            currentPreSale = SafeMath.add(currentPreSale,totalTokens);
        }else if(currentState==ICOSaleState.PublicSale){
            require(SafeMath.add(currentPublicSale,totalTokens)<=maxPublicSale);
            currentPublicSale = SafeMath.add(currentPublicSale,totalTokens);
        }
        currentSupply = SafeMath.add(currentSupply,totalTokens);
        require(currentSupply<=tokenCreationMax);
        addToBalances(msg.sender,totalTokens);
        token.increaseEthRaised(msg.value);
        token.increaseUSDRaised(usd);
        numberOfBackers++;
        if(!ownerAddr.send(this.balance))throw;
    }
    
     
     
    function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr)  onlyOwner returns (uint)
    {   
        bool  valueSent;
        require(token.isValid());
     ICOSaleState currentState = getStateFunding();

        if(!transactionsClaimed[txHash]){
            var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
            if(a){
                valueSent = true;
                transactionsClaimed[txHash] = true;
                  
               allottTokensBTC(addr,b,currentState);
                return 1;
               }
        }
    }
    
     
    function allottTokensBTC(address addr,uint256 value,ICOSaleState state) internal{
        ICOSaleState currentState = getStateFunding();
        require(currentState!=ICOSaleState.Failed);
        require(currentState!=ICOSaleState.Success);
        var (discount,usd) = pricingstrategy.totalDiscount(state,value,"bitcoin");
        uint256 tokens = usd*tokensPerUSD;
        uint256 totalTokens = SafeMath.add(tokens,SafeMath.div(SafeMath.mul(tokens,discount),100));
        if(currentState==ICOSaleState.PrivateSale){
            require(SafeMath.add(currentPrivateSale,totalTokens)<=maxPrivateSale);
            currentPrivateSale = SafeMath.add(currentPrivateSale,totalTokens);
        }else if(currentState==ICOSaleState.PreSale){
            require(SafeMath.add(currentPreSale,totalTokens)<=maxPreSale);
            currentPreSale = SafeMath.add(currentPreSale,totalTokens);
        }else if(currentState==ICOSaleState.PublicSale){
            require(SafeMath.add(currentPublicSale,totalTokens)<=maxPublicSale);
            currentPublicSale = SafeMath.add(currentPublicSale,totalTokens);
        }
       currentSupply = SafeMath.add(currentSupply,totalTokens);
       require(currentSupply<=tokenCreationMax);
       addToBalances(addr,totalTokens);
       token.increaseBTCRaised(value);
       token.increaseUSDRaised(usd);
       numberOfBackers++;
    }


     

    function alottTokensExchange(address contributor,uint256 value) public onlyOwner{
        token.addToBalances(contributor,value);
        currentSupply = SafeMath.add(currentSupply,value);
    }

    function finalizeTokenSale() public onlyOwner{
        ICOSaleState currentState = getStateFunding();
        if(currentState!=ICOSaleState.Success) throw;
        token.finalizeICO();
    }

     
    function killContract() public onlyOwner{
        selfdestruct(ownerAddr);
    }


     
    function changeEndPrivateSale(uint256 _newend) public onlyOwner{
        endprivate = _newend;
    }

    function changeEndPreSale(uint256 _newend) public onlyOwner{
        endpresale  = _newend;
    }


    function changeTokensPerUSD(uint256 _val) public onlyOwner{
        tokensPerUSD = _val;
    }

    function getStateFunding() returns (ICOSaleState){
       if(now>token.fundingStartBlock() && now<=endprivate) return ICOSaleState.PrivateSale;
       if(now>endprivate && now<=endpresale) return ICOSaleState.PreSale;
       if(now>endpresale && now<=token.fundingEndBlock()) return ICOSaleState.PublicSale;
       if(now>token.fundingEndBlock() && token.usdraised()<token.minCapUSD()) return ICOSaleState.Failed;
       if(now>token.fundingEndBlock() && token.usdraised()>=token.minCapUSD()) return ICOSaleState.Success;
    }

    

}