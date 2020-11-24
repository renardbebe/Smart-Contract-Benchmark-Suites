 

pragma solidity ^0.4.17;

  

 
contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 
contract Token {
     

     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
}

 
contract StandardToken is Token {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


contract RealFundToken is StandardToken {

  string constant public name = "REAL FUND Token";
  string constant public symbol = "REF";
  uint8 constant public decimals = 8;
  uint constant multiplier = 10 ** uint(decimals);

  event Deployed(uint indexed _totalSupply);
  event Burnt(address indexed _receiver, uint indexed _num, uint indexed _totalSupply);

  function RealFundToken(address walletAddress) public {
    require(walletAddress != 0x0);

    totalSupply = 5000000000000000;
    balances[walletAddress] = totalSupply;
    Transfer(0x0, walletAddress, totalSupply);
  }

  function burn(uint num) public {
        require(num > 0);
        require(balances[msg.sender] >= num);
        require(totalSupply >= num);

        uint preBalance = balances[msg.sender];

        balances[msg.sender] -= num;
        totalSupply -= num;
        Burnt(msg.sender, num, totalSupply);
        Transfer(msg.sender, 0x0, num);

        assert(balances[msg.sender] == preBalance - num);
    }
}

contract PreSale {
    RealFundToken public token;
    address public walletAddress;
    
    uint public amountRaised;
    
    uint public bonus;
    uint public price;    
    uint public minSaleAmount;

    function PreSale(RealFundToken _token, address _walletAddress) public {
        token = RealFundToken(_token);
        walletAddress = _walletAddress;
        bonus = 25;
        price = 200000000;
        minSaleAmount = 100000000;
    }

    function () public payable {
        uint amount = msg.value;
        uint tokenAmount = amount / price;
        require(tokenAmount >= minSaleAmount);
        amountRaised += amount;
        token.transfer(msg.sender, tokenAmount * (100 + bonus) / 100);
    }
    
    function ChangeWallet(address _walletAddress) public {
        require(msg.sender == walletAddress);
        walletAddress = _walletAddress;
    }

    function TransferETH(address _to, uint _amount) public {
        require(msg.sender == walletAddress);
        _to.transfer(_amount);
    }

    function TransferTokens(address _to, uint _amount) public {
        require(msg.sender == walletAddress);
        token.transfer(_to, _amount);
    }

    function ChangeBonus(uint _bonus) public {
        require(msg.sender == walletAddress);
        bonus = _bonus;
    }
    
    function ChangePrice(uint _price) public {
        require(msg.sender == walletAddress);
        price = _price;
    }
    
    function ChangeMinSaleAmount(uint _minSaleAmount) public {
        require(msg.sender == walletAddress);
        minSaleAmount = _minSaleAmount;
    }
}