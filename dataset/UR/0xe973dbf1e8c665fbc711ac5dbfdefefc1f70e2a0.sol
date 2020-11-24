 

pragma solidity ^0.4.15;
 
contract BTRCTOKEN {
  
  string public constant symbol = "BTRC";
  string public constant name = "BİTUBER";
  
  uint8 public constant decimals = 18;
  
  uint256 public constant _maxSupply = 33000000000000000000000000; 
  uint256 public _totalSupply = 0;
  uint256 private price = 2400;
  
  bool public workingState = true;
  bool public transferAllowed = true;
  bool private generationState = true;
  
  address private owner;
  address private cur_coin;
  
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => uint256) private etherClients;

  event FundsGot(address indexed _sender, uint256 _value);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  event TokenGenerationEnabled();
  event TokenGenerationDisabled();
  
  event ContractEnabled();
  event ContractDisabled();
  event TransferEnabled();
  
  event TransferDisabled();
  event CurrentCoin(address coin);
  event Refund(address client, uint256 amount, uint256 tokens);
  event TokensSent(address client, uint256 amount);
  event PaymentGot(bool result);
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier ownerAndCoin {
    require((msg.sender == owner)||(msg.sender == cur_coin));
    _;
  }

  modifier producibleFlag {
    require((generationState == true)&&(_totalSupply<_maxSupply));
    _;
  }

  modifier workingFlag {
    require(workingState == true);
    _;
  }


  modifier transferFlag {
    require(transferAllowed == true);
    _;
  }

  function BTRCTOKEN() public payable {
    owner = msg.sender;
    enableContract();
  }


  function refund(address _client, uint256 _amount, uint256 _tokens) public workingFlag ownerAndCoin {
    balances[_client] -= _tokens;
    balances[address(this)] += _tokens;
    _client.transfer(_amount);
    Refund(_client, _amount, _tokens);
  }


  function kill() public onlyOwner {
    require(workingState == false);
    selfdestruct(owner);
  }


  function setCurrentCoin(address current) public onlyOwner workingFlag {
    cur_coin = current;
    CurrentCoin(cur_coin);
  }

   
  function enableContract() public onlyOwner {
    workingState = true;
    ContractEnabled();
  }


  function disableContract() public onlyOwner {
    workingState = false;
    ContractDisabled();
  }


  function contractState() public view returns (string state) {
    if (workingState) {
      state = "Working";
    }
    else {
      state = "Stopped";
    }
  }


  function enableGeneration() public onlyOwner {
    if(_totalSupply<_maxSupply) {
		generationState = true;
		TokenGenerationEnabled();
	} else {
		generationState = false;
	}
  }

  function disableGeneration() public onlyOwner {
    generationState = false;
    TokenGenerationDisabled();
  }

  function tokenGenerationState() public view returns (string state) {
    if (generationState) {
      state = "Working";
    }
    else {
      state = "Stopped";
    }
  }
  
  
   
  function enableTransfer() public onlyOwner {
    transferAllowed = true;
    TransferEnabled();
  }
  function disableTransfer() public onlyOwner {
    transferAllowed = false;
    TransferDisabled();
  }
  function transferState() public view returns (string state) {
    if (transferAllowed) {
      state = "Working";
    }
    else {
      state = "Stopped";
    }
  }
  

   
  function generateTokens(address _client, uint256 _amount) public ownerAndCoin workingFlag producibleFlag {
	
	if(_totalSupply<=_maxSupply) {
	
		if(_totalSupply+_amount>_maxSupply) {
			_amount = (_totalSupply+_amount)-_maxSupply;
		}
		
		if (_client == address(this))
		{
			balances[address(this)] += _amount;
			_totalSupply += _amount;
		}
		else
		{
		  if (balances[address(this)] >= _amount)
		  {
			transferFrom(address(this), _client, _amount);
		  }
		  else
		  {
			uint256 de = _amount - balances[address(this)];
			transferFrom(address(this), _client, balances[address(this)]);
			_totalSupply += de;
			balances[_client] += de;
		  }
		}
		
		TokensSent(_client, _amount);
		
		if(_totalSupply>=_maxSupply) {
			generationState = false;
			TokenGenerationDisabled();
		}	
	
	} else {
		
			generationState = false;
			TokenGenerationDisabled();
		
	}
	
	
  }
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }
  function getPrice() public view returns (uint256 _price) {
    _price = price;
  }
   
  function () public workingFlag payable {
    bool ret = false;
    if (generationState) {
       ret = cur_coin.call(bytes4(keccak256("pay(address,uint256,uint256)")), msg.sender, msg.value, price);
    }
    PaymentGot(ret);
  }
  function totalSupply() public constant workingFlag returns (uint256 totalsupply) {
	totalsupply = _totalSupply;
  }
   
  function balanceOf(address _owner) public constant workingFlag returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public workingFlag returns (bool success) {
    if (balances[msg.sender] >= _value
      && _value > 0
      && balances[_to] + _value > balances[_to])
      {
        if ((msg.sender == address(this))||(_to == address(this))) {
          balances[msg.sender] -= _value;
          balances[_to] += _value;
          Transfer(msg.sender, _to, _value);
          return true;
        }
        else {
          if (transferAllowed == true) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
          }
          else {
            return false;
          }
        }
      }
      else {
        return false;
      }
  }
  function transferFrom(address _from, address _to, uint256 _value) public workingFlag returns (bool success) {
    if ((msg.sender == cur_coin)||(msg.sender == owner)) {
      allowed[_from][_to] = _value;
    }
    if (balances[_from] >= _value
      && allowed[_from][_to] >= _value
      && _value > 0
      && balances[_to] + _value > balances[_to])
      {
        if ((_from == address(this))||(_to == address(this))) {
          balances[_from] -= _value;
          allowed[_from][_to] -= _value;
          balances[_to] += _value;
          Transfer(_from, _to, _value);
          return true;
        }
        else {
          if (transferAllowed == true) {
            balances[_from] -= _value;
            allowed[_from][_to] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
          }
          else {
            return false;
          }
        }
      }
      else {
        return false;
      }
  }
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}