 

pragma solidity ^0.4.11;

 
contract SafeMath {

function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}


contract EvenCoin is SafeMath {

     
    string public constant name = "EvenCoin";
    string public constant symbol = "EVN";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public founder;       
     
    bool public isFinalized;               
    bool public saleStarted;  
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint256 public soldCoins;
    uint256 public totalGenesisAddresses;
    uint256 public currentGenesisAddresses;
    uint256 public initialSupplyPerAddress;
    uint256 public initialBlockCount;
    uint256 private minedBlocks;
    uint256 public rewardPerBlockPerAddress;
    uint256 private availableAmount;
    uint256 private availableBalance;
    uint256 private totalMaxAvailableAmount;
    uint256 public constant founderFund = 5 * (10**6) * 10**decimals;    
    uint256 public constant preMinedFund = 10 * (10**6) * 10**decimals;    
    uint256 public tokenExchangeRate = 2000;  
    mapping (address => uint256) balances;
    mapping (address => bool) public genesisAddress;


     
    event CreateEVN(address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    function EvenCoin()
    {
      isFinalized = false;                    
      saleStarted = false;
      soldCoins = 0;
      founder = '0x9e8De5BE5B046D2c85db22324260D624E0ddadF4';
      initialSupplyPerAddress = 21250 * 10**decimals;
      rewardPerBlockPerAddress = 898444106206663;
      totalGenesisAddresses = 4000;
      currentGenesisAddresses = 0;
      initialBlockCount = 0;
      balances[founder] = founderFund;     
      CreateEVN(founder, founderFund);   



    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function currentEthBlock() constant returns (uint256 blockNumber)
    {
    	return block.number;
    }

    function currentBlock() constant returns (uint256 blockNumber)
    {
      if(initialBlockCount == 0){
        return 0;
      }
      else{
      return block.number - initialBlockCount;
    }
    }

    function setGenesisAddressArray(address[] _address) public returns (bool success)
    {
      if(initialBlockCount == 0) throw;
      uint256 tempGenesisAddresses = currentGenesisAddresses + _address.length;
      if (tempGenesisAddresses <= totalGenesisAddresses )
    	{
    		if (msg.sender == founder)
    		{
          currentGenesisAddresses = currentGenesisAddresses + _address.length;
    			for (uint i = 0; i < _address.length; i++)
    			{
    				balances[_address[i]] = initialSupplyPerAddress;
    				genesisAddress[_address[i]] = true;
    			}
    			return true;
    		}
    	}
    	return false;
    }

    function availableBalanceOf(address _address) constant returns (uint256 Balance)
    {
    	if (genesisAddress[_address])
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 23652000) return balances[_address];
    		  availableAmount = rewardPerBlockPerAddress*minedBlocks;
    		  totalMaxAvailableAmount = initialSupplyPerAddress - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
    	else {
    		return balances[_address];
      }
    }

    function totalSupply() constant returns (uint256 totalSupply)
    {
      if (initialBlockCount != 0)
      {
      minedBlocks = block.number - initialBlockCount;
      if(minedBlocks % 2 != 0){
        minedBlocks = minedBlocks - 1;
      }
    	availableAmount = rewardPerBlockPerAddress*minedBlocks;
    }
    else{
      availableAmount = 0;
    }
    	return availableAmount*totalGenesisAddresses+founderFund+preMinedFund;
    }

    function maxTotalSupply() constant returns (uint256 maxSupply)
    {
    	return initialSupplyPerAddress*totalGenesisAddresses+founderFund+preMinedFund;
    }

    function transfer(address _to, uint256 _value)
    {
      if (genesisAddress[_to]) throw;

      if (balances[msg.sender] < _value) throw;

      if (balances[_to] + _value < balances[_to]) throw;

      if (genesisAddress[msg.sender])
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 23652000)
    	     {
    		       availableAmount = rewardPerBlockPerAddress*minedBlocks;
    		       totalMaxAvailableAmount = initialSupplyPerAddress - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
    }

     
    function () payable {
       
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
       
      if (now > firstWeek && now < secondWeek){
        tokenExchangeRate = 1500;
      }
      else if (now > secondWeek && now < thirdWeek){
        tokenExchangeRate = 1000;
      }
      else if (now > thirdWeek){
        tokenExchangeRate = 500;
      }
       
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(soldCoins, tokens);

       
      if (preMinedFund < checkedSupply) throw;   
      soldCoins = checkedSupply;
       
      balances[msg.sender] += tokens;   
      CreateEVN(msg.sender, tokens);   
    }

     
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != founder) throw;  
      if (soldCoins < preMinedFund){
        uint256 remainingTokens = safeSubtract(preMinedFund, soldCoins);
        uint256 checkedSupply = safeAdd(soldCoins, remainingTokens);
        if (preMinedFund < checkedSupply) throw;
        soldCoins = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreateEVN(msg.sender, remainingTokens);
      }
       
      if(!founder.send(this.balance)) throw;
      isFinalized = true;   
      if (block.number % 2 != 0){
        initialBlockCount = safeAdd(block.number, 1);
      }
      else{
        initialBlockCount = block.number;
      }
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != founder) throw;  
      firstWeek = now + 1 weeks;  
      secondWeek = firstWeek + 1 weeks;  
      thirdWeek = secondWeek + 1 weeks;  
      saleStarted = true;  
    }


}