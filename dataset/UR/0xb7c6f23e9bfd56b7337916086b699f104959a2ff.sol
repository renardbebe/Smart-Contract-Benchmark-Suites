 

pragma solidity ^0.4.8;
 

 
contract Owned {

     
    address owner;

     
    function Owned() {
        owner = msg.sender;
    }

         
    function changeOwner(address newOwner) onlyowner {
        owner = newOwner;
    }


     
    modifier onlyowner() {
        if (msg.sender==owner) _;
    }
}

 
 
contract Token is Owned {

     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC20Token is Token
{

    function transfer(address _to, uint256 _value) returns (bool success)
    {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
    {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 
contract ArtCash is ERC20Token
{

    bool public isTokenSale = true;
    uint256 public price;
    uint256 public limit;

    address walletOut = 0x0882ea6417087786d9e404e85e6d4ed2a8f9fe51;

    function getWalletOut() constant returns (address _to) {
        return walletOut;
    }

    function () external payable  {
        if (isTokenSale == false) {
            throw;
        }

        uint256 tokenAmount = (msg.value  * 100000000) / price;

        if (balances[owner] >= tokenAmount && balances[msg.sender] + tokenAmount > balances[msg.sender]) {
            if (balances[owner] - tokenAmount < limit) {
                throw;
            }
            balances[owner] -= tokenAmount;
            balances[msg.sender] += tokenAmount;
            Transfer(owner, msg.sender, tokenAmount);
        } else {
            throw;
        }
    }

    function stopSale() onlyowner {
        isTokenSale = false;
    }

    function startSale() onlyowner {
        isTokenSale = true;
    }

    function setPrice(uint256 newPrice) onlyowner {
        price = newPrice;
    }

    function setLimit(uint256 newLimit) onlyowner {
        limit = newLimit;
    }

    function setWallet(address _to) onlyowner {
        walletOut = _to;
    }

    function sendFund() onlyowner {
        walletOut.send(this.balance);
    }

     
    string public name;                  
    uint8 public decimals;               
    string public symbol;                
    string public version = '1.0';       

    function ArtCash()
    {
        totalSupply = 10000000000000000;
        balances[msg.sender] = 10000000000000000;   
        name = 'ArtCash';
        decimals = 8;
        symbol = 'AYC';
        price = 109462678000000;
        limit = 0;
    }

    

    
}